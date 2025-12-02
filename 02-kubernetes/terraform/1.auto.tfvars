vpc_subnet = {
    subnet1  = {
        name = "subnet1",
        zone = "ru-central1-a",
        cidr = ["192.168.10.0/24"]
        },
    subnet2 = {
        name = "subnet2",
        zone = "ru-central1-b",
        cidr = ["192.168.20.0/24"]
    }
}

instance_resources = {
        master = {
            name            = "master",
            count           = 1,
            platform_id     = "standard-v1",
            cores           = 2, 
            memory          = 4, 
            core_fraction   = 5,
            disk_image      = "ubuntu-2204-lts",
            disk_type       = "network-hdd",
            disk_size       = 10,
            nat             = true
        }
        worker = {
            name            = "worker",
            count           = 2,
            platform_id     = "standard-v1",
            cores           = 4, 
            memory          = 8, 
            core_fraction   = 20,
            disk_image      = "ubuntu-2204-lts",
            disk_type       = "network-hdd",
            disk_size       = 10,
            nat             = true
        }
    }