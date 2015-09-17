Wms::Role.create(name: 'staff')
Wms::Role.create(name: 'admin')
Wms::Role.create(name: 'super_admin')

Wms::Depot.create(name: "duesseldorf", country: "de")
Wms::Depot.create(name: "best", country: "nl")
Wms::Depot.create(name: "birmingham", country: "gb")