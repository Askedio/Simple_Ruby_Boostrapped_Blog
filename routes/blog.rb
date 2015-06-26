module Sinatra
  module SimpleRubyBlog
    module Routing
      module BlogAdmin

		  def self.registered(app)
			app.post '/create/upload'   do 
			  protected!
			  halt 500 unless !params['image'].nil?
			  accepted_formats = [".jpg", ".png", ".gif"]
			  halt 500 unless accepted_formats.include? File.extname(params['image'][:filename]) 
			  image='public/assests/images/' + params['image'][:filename]

			  new_image = File.open(image, "wb") do |f|
				  f.write(params['image'][:tempfile].read)
			  end

			  if !Cloudinary.config.api_key.blank?
				  upload =  Cloudinary::Uploader.upload image
				  image = upload['secure_url']
				  File.delete(image)|| halt(500)
			  end

			  "<script data-cfasync=\"false\">top.$('.mce-btn.mce-open').parent().find('.mce-textbox').val('#{image}').closest('.mce-window').find('.mce-primary').click();</script>"
			 end

			  app.get '/create' do 
				protected!
				erb :"admin/post/control", :layout => :'layouts/control' 
			  end

          app.post '/create' do
			protected!
			image = ''
			if !params['myfile'].nil?
				accepted_formats = [".jpg", ".png", ".gif"]
				halt 500 unless accepted_formats.include? File.extname(params['myfile'][:filename]) 
				image = 'public/assests/images/' + params['myfile'][:filename]
				new_image = File.open(image, "wb") do |f|
					f.write(params['myfile'][:tempfile].read)
				end
				
				new_name = 'public/assests/images/' + params[:title].slugify + File.extname(params['myfile'][:filename])
				File.rename(image, new_name)|| halt(500)
				
				if !Cloudinary.config.api_key.blank?
					upload = Cloudinary::Uploader.upload(new_name, :use_filename => true)
					image = upload['secure_url']
					File.delete(new_name)|| halt(500)
				end
			end

			if Post.count(:slug => params[:title].slugify) > 0
				params[:title] = "#{params[:title]} #{rand(10)}"
			end
			 

			person ||= Person.first(:name => session[:username]) || halt(404)
			new_post = person.posts.create(:draft => params[:draft],
							:tags => Tag.all(:id => add_missing(params[:tags], Tag)),
							:categories => Category.all(:id => add_missing(params[:category], Category)),
							:title => params[:title],
							:slug => params[:title].slugify,
							:body => params[:body],
							:image => image, 
							:featured => (!params[:featured].nil? ? Featured.new : nil),

							:position => params[:position])

			if new_post
			  new_post2 ||= Post.first(:title => params[:title]) || halt(500)
			  flash[:success] = true
			  redirect "/#{new_post2.slug}"
			else
			do_error new_post.errors
				redirect "/create"
			end
		  end

          app.post '/edit/:id' do
			  protected!
			  post ||= Post.get(params[:id]) || halt(404) 

			  if post.update(:draft => params[:draft],
							  :tags => Tag.all(:id => add_missing(params[:tags], Tag)),
							  :categories => Category.all(:id => add_missing(params[:category], Category)),
							  :title => params[:title],
							  :slug => params[:title].gsub(/<\/?[^>]*>/, "").slugify, 
							  :body => params[:body], 
							  :image => params[:myfile],
							  :template => params[:template],
							  :featured => featured(params[:featured], post),
							  :position => params[:position])
				flash[:success] = true
			  else
				do_error post.errors
			  end

			  redirect "/#{params[:id]}"
          end

          app.get '/edit/:id' do
			  protected!
			  post ||= Post.get(params[:id]) || halt(404)
			  @post = post
			  erb :"admin/post/control", :layout => :'layouts/control' 
          end

          app.get '/delete/:id' do
			  protected!
			  post ||= Post.get(params[:id]) || halt(404)
			  halt 500 unless post.destroy
			  redirect '/'
          end
        end
      end
    end
  end
end