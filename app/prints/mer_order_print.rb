# encoding: utf-8

class MerOrderPrint < Prawn::Document
	def single_order(order)
		font("#{Wms::Engine.root}/lib/fonts/DejaVuSans.ttf") do
			text "Order Commodities", size: 20, align: :center

      dir_path = "#{Wms::Engine.root}/print/barcode/#{Time.now.strftime("%Y%m%d")}"
      Dir.mkdir dir_path unless Dir.exist? dir_path
      file_path = "#{dir_path}/#{order.tp_order_no}.png"
      File.open(file_path, "wb+") {|f| f.write Wms::Depot.gen_barcode(order.tp_order_no) }

      move_down 20
      text "Order No.:  #{order.tp_order_no}", size: 14 
      move_down 5
      text "Order No. Barcode:", size: 14
      image file_path, width: 250, height: 100, align: :center
      move_down 5
      
    end
    font("#{Wms::Engine.root}/lib/fonts/simhei.ttf") do
      data_detail = [["Qty","Name", "Chinese Name", "Brand", "Model", "Color", "Size", "Grade"]]
      #invoice_message.invoice_details.asc(:item).each {|i| data_detail << [i.item.to_i.to_s, i.description, i.qty, i.unit_price, i.vat, i.total]}
      order.mer_batch_skus.each do |mbs|
        if ms = Wms::MerSku.where(sku_no: mbs.sku_no, merchant: order.mer_outbound_commodity.merchant).first
          data_detail << [mbs.quantity.to_s, ms.name || "", ms.chinese_name || "", ms.brand || "", ms.model || "", ms.color || "", ms.size || "", ms.grade || ""]
        else
          data_detail << [mbs.quantity.to_s, mbs.sku_no.to_s, "", "", "", "", "", ""]
        end
      end
      table data_detail, :width => 540, :column_widths => [30, 130, 90, 90, 50, 50, 50, 50], :cell_style => { :size => 11 } do 
        cells.padding = 2
        cells.borders = [:top,:bottom, :right, :left]
      end
    end
		render
	end


  def batch_order(orders)
    order_count = 0
    order_all_count = orders.count
    orders.each do |order|
      order_count += 1
      single_order(order)
      start_new_page if order_count < order_all_count
    end
    render
  end
end