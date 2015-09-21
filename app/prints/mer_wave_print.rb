# encoding: utf-8

class MerWavePrint < Prawn::Document
	def single_mer_wave(mw)
		font("#{Wms::Engine.root}/lib/fonts/DejaVuSans.ttf") do
			text mw.wave_no.start_with?('wave') ? "Sorting Commodities" : "Order Commodities", size: 20, align: :center

      dir_path = "#{Wms::Engine.root}/print/barcode/#{Time.now.strftime("%Y%m%d")}"
      Dir.mkdir dir_path unless Dir.exist? dir_path
      file_path = "#{dir_path}/#{mw.wave_no}.png"
      File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(mw.wave_no) }

      move_down 20
      text mw.wave_no.start_with?('wave') ? "Wave No.:  #{mw.wave_no}" : "Order No.:  #{mw.wave_no}", size: 14 
      move_down 5
      text mw.wave_no.start_with?('wave') ? "Wave No. Barcode:" : "Order No. Barcode:", size: 14
      image file_path, width: 250, height: 100, align: :center
      move_down 5
      
    end
    font("#{Wms::Engine.root}/lib/fonts/simhei.ttf") do
      data_detail = [["Qty","Name", "Brand", "Model", "Color", "Size", "Grade"]]
      #invoice_message.invoice_details.asc(:item).each {|i| data_detail << [i.item.to_i.to_s, i.description, i.qty, i.unit_price, i.vat, i.total]}
      mw.mer_wave_skus.each do |mws|
        if ms = Wms::MerSku.where(sku_no: mws.sku_no, merchant: mw.merchant).first
          data_detail << [(mws.quantity-mws.allocated_quantity.presence || 0).to_s, ms.name || "", ms.brand || "", ms.model || "", ms.color || "", ms.size || "", ms.grade || ""]
        else
          data_detail << [(mws.quantity-mws.allocated_quantity.presence || 0).to_s, mws.sku_no.to_s, "", "", "", "", ""]
        end
      end
      table data_detail, :column_widths => [40, 150, 110, 60, 60, 60, 60], :cell_style => { :size => 11 } do 
        cells.padding = 2
        cells.borders = [:top,:bottom, :right, :left]
      end
    end
		render
	end


  def batch_mer_wave(mws)
    mw_count = 0
    mw_all_count = mws.count
    mws.each do |mw|
      mw_count += 1
      single_mer_wave(mw)
      start_new_page if mw_count < mw_all_count
    end
    render
  end
end