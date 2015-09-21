# encoding: utf-8

class ShelfNumPrint < Prawn::Document
	def shelf_num_pdf(num)
    pages = num/8 + (num%8==0? 0 : 1)
		font("#{Wms::Engine.root}/lib/fonts/DejaVuSans.ttf") do

      ipage = 1
      inum = 1
      dir_path = "#{Wms::Engine.root}/print/barcode/#{Time.now.strftime("%Y%m%d")}"
      Dir.mkdir dir_path unless Dir.exist? dir_path
      while(ipage <= pages)
  			define_grid(:columns => 2, :rows => 4, :gutter => 10)
        grid(0,0).bounding_box do
          text "Shelf Num: #{inum}"
          file_path = "#{dir_path}/#{inum}.png"
          File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(inum.to_s) }
          image file_path, width: 220, height: 100, align: :center
          break if inum >= num
          inum += 1
        end
        grid(0,1).bounding_box do
          text "Shelf Num: #{inum}"
          file_path = "#{dir_path}/#{inum}.png"
          File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(inum.to_s) }
          image file_path, width: 220, height: 100, align: :center
          break if inum >= num
          inum += 1
        end
        grid(1,0).bounding_box do
          text "Shelf Num: #{inum}"
          file_path = "#{dir_path}/#{inum}.png"
          File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(inum.to_s) }
          image file_path, width: 220, height: 100, align: :center
          break if inum >= num
          inum += 1
        end
        grid(1,1).bounding_box do
          text "Shelf Num: #{inum}"
          file_path = "#{dir_path}/#{inum}.png"
          File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(inum.to_s) }
          image file_path, width: 220, height: 100, align: :center
          break if inum >= num
          inum += 1
        end
        grid(2,0).bounding_box do
          text "Shelf Num: #{inum}"
          file_path = "#{dir_path}/#{inum}.png"
          File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(inum.to_s) }
          image file_path, width: 220, height: 100, align: :center
          break if inum >= num
          inum += 1
        end
        grid(2,1).bounding_box do
          text "Shelf Num: #{inum}"
          file_path = "#{dir_path}/#{inum}.png"
          File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(inum.to_s) }
          image file_path, width: 220, height: 100, align: :center
          break if inum >= num
          inum += 1
        end
        grid(3,0).bounding_box do
          text "Shelf Num: #{inum}"
          file_path = "#{dir_path}/#{inum}.png"
          File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(inum.to_s) }
          image file_path, width: 220, height: 100, align: :center
          break if inum >= num
          inum += 1
        end
        grid(3,1).bounding_box do
          text "Shelf Num: #{inum}"
          file_path = "#{dir_path}/#{inum}.png"
          File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(inum.to_s) }
          image file_path, width: 220, height: 100, align: :center
          break if inum >= num
          inum += 1
        end

        #grid.show_all
        if ipage < pages
          start_new_page
        end
        ipage += 1
      end
    end
		render
	end

end