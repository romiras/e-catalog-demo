class RegistrationsController < ApplicationController
  include OffsitePayments::Integrations

  before_filter :set_registration,
    only: [:review, :complete, :done, :failed]

  # map PayPal's status to internal presentation
  PAYMENT_STATUS = {
    "verified" => Registration::REVIEW,
    "Completed" => Registration::COMPLETED,
    "Pending" => Registration::PENDING,
    "Failed" => Registration::FAILED,
    "Refunded" => Registration::REFUNDED,
    "Reversed" => Registration::FAILED,
    "Denied" => Registration::FAILED,
    "Expired" => Registration::EXPIRED
  }

  # GET /registrations/new
  def new
    @registration = Registration.new
    @poster = Poster.find_by sku: params[:sku]
  end

  # POST /registrations
  def create
    registration_params
    @params[:client_ip] = request.remote_ip
    poster = Poster.find_by(sku: params[:sku])
    @params[:poster_id] = poster.id
    @registration = Registration.new(@params)
    if @registration.save
      money = Money.from_amount(poster.price, GW_CONFIG['currency_code'])
      response = GATEWAY.setup_purchase(money.cents,
        ip: @params[:client_ip],
        return_url: review_registration_url(id: @registration.id),
        cancel_return_url: failed_registration_url(id: @registration.id),
        currency: GW_CONFIG['currency_code'],
        allow_guest_checkout: true,
        #charset: 'UTF-8',
        items: [
          {
            #category: "Digital",
            #number: poster.sku,
            name: poster.name,
            #description: "Order description",
            amount: money.cents,
            quantity: "1"
          }
        ]
      )
      logger.debug(response.inspect)
      redirect_to GATEWAY.redirect_url_for(response.token)
    else
      @poster = Poster.find_by id: @params[:poster_id]
      render :new
    end
#  rescue StandardError
#    #
  end

  protect_from_forgery except: [:hook]
  def hook
    params.permit! # Permit all input params
    notification = Paypal::Notification.new(request.raw_post)
    if notification.acknowledge
      @registration = Registration.find notification.item_id
      if notification.complete?
        logger.debug "====== txn complete"
        @registration.update_attributes status: notification.status, purchased_at: notification.received_at
      end
    else
      logger.info "ERROR: the message has not been aknowledged."
    end
    render nothing: true
  end

  def failed
    # {"token"=>"EC-39C26951BV893031R", "PayerID"=>"QZ5CTDH8DEUAY", "id"=>"123"}
    response = GATEWAY.details_for(params[:token])
    logger.debug(response.inspect)
    txn = store_transaction(@registration, response.authorization, response.params)
    txn.save!
    logger.debug "====== txn: #{txn.inspect}"
    @message = response.message
    flash[:notice] = @message
  end

  def review
    # {"token"=>"EC-J9C26957BV893032S", "PayerID"=>"CZ5CTDH8DEUAY", "id"=>"123"}
    @token = params[:token]
    @payer_id = params[:PayerID]
    response = GATEWAY.details_for(@token)

    logger.debug(response.inspect)
    @response_params = response.params
    @registration.update_attribute :status, Registration::REVIEW

    if response.success?
      @money = Money.from_amount(BigDecimal.new(@response_params['amount']), GW_CONFIG['currency_code'])
    else
      flash[:error] = response.message
      redirect_to failed_registration_path(@registration)
    end
  end

  def complete
    poster = @registration.poster
    money = Money.from_amount(poster.price, GW_CONFIG['currency_code'])
    response = GATEWAY.purchase(money.cents,
      :currency => GW_CONFIG['currency_code'],
      :ip       => request.remote_ip,
      :payer_id => params[:PayerID],
      :token    => params[:token]
    )
    logger.debug(response.inspect)
    # Read about Payment Receiving Preferences: http://www.ezgenerator.com/howto.php?entry_id=1326578971&title=paypal-order-processing-problems
    response_params = response.params
    txn = store_transaction(@registration, response.authorization, response_params)
    txn.save!
    logger.debug "====== txn: #{txn.inspect}"

    if !response.success?
      flash[:error] = response.message
      redirect_to root_path; return
    else
      failed_details = response_acknowledged?(response_params, money)
      if failed_details.empty?
        complete_registration(@registration, response_params)
        redirect_to done_registration_path(@registration); return
      else
        logger.info "SECURITY: response NOT acknowledged! Failed on #{failed_details.inspect}"
        flash[:error] = "A payment did not succeed."
        redirect_to failed_registration_path(@registration); return
      end
    end
  end

  def done
    flash[:notice] = "Complete"
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_registration
      @registration = Registration.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def registration_params
      @params = params.require(:registration).permit(:poster_id, :full_name, :company, :email, :phone, :organization, :client_ip)
    end

    def store_transaction(registration, authr_nr, params)
      registration.payment_transactions.new(
        status: params["payment_status"],
        gross_amount: params['gross_amount'],
        currency_code: params['gross_amount_currency_id'],
        transaction_id: authr_nr,
        notification_params: params
      )
    end

    def update_registration_status(registration, params)
      registration.update_attribute(
        :status, PAYMENT_STATUS[params['payment_status']]
      )
    end

    def complete_registration(registration, params)
      registration.update_attributes(
        status: PAYMENT_STATUS[params['payment_status']],
        purchased_at: params['payment_date']
      )
    end

    def response_acknowledged?(params, money)
      details = []
      details << "merchant_id"    unless params['secure_merchant_account_id'].eql?(GW_CONFIG['merchant_id'])
      details << "payment_status" unless params['payment_status'].eql?('Completed')
      details << "gross_amount"   unless params['gross_amount'].eql?(money.format(symbol: ''))
      details << "currency_code"  unless params['gross_amount_currency_id'].eql?(GW_CONFIG['currency_code'])
      details
    end
end
