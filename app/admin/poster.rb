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
        filename = attachment.original_filename.to_s
        s3_file = FileUploader.upload_to_s3(attachment.tempfile, filename)
        if s3_file
          @poster.create_document(filename: filename)
        end

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
          filename = attachment.original_filename.to_s
          s3_file = FileUploader.upload_to_s3(attachment.tempfile, filename)
          if s3_file
            if @poster.document
              @poster.document.update_attribute(:filename, filename)
            else
              @poster.create_document(filename: filename)
            end
          end
        end

        redirect_to admin_posters_path
      else
        render :edit
      end
    end

  end

end
