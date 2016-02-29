require 'file_uploader'

ActiveAdmin.register Poster do
  
  permit_params :name, :sku, :price, :attachment

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs "Poster details", multipart: true do
      f.input :name
      f.input :sku
      f.input :price
      f.input :attachment, as: :file
    end
    f.actions
  end

  controller do

    def create
      attrs = permitted_params[:poster]
      attachment = attrs.delete(:attachment)
      @poster = Poster.new(attrs)
      if @poster.save
        # upload
        FileUploader.upload_to_s3(attachment.tempfile, ENV['S3_BUCKET'], ENV['CAT_FOLDER'], attachment.original_filename)

        redirect_to admin_poster_path(@poster)
      else
        render :new
      end
    end

    def update
      attrs = permitted_params[:poster]
      attachment = attrs.delete(:attachment)
      @poster = Poster.find(params[:id])
      if @poster.save
        # upload
        if attachment
          FileUploader.upload_to_s3(attachment.tempfile, ENV['S3_BUCKET'], ENV['CAT_FOLDER'], attachment.original_filename)
        end

        redirect_to admin_posters_path
      else
        render :edit
      end
    end

  end

end
