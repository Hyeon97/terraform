output "additional_disk_info_list" {
  description = "생성된 모든 추가 디스크의 전체 정보"
  value = [
    for disk in openstack_blockstorage_volume_v3.additional_disk : {
      id          = disk.id
      name        = disk.name
      size        = disk.size
      volume_type = disk.volume_type
    }
  ]
}