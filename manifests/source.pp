define chocolatey::source (
  $ensure      = 'present',
  $source_name = $title,
  $location    = $title,
  $enable      = true,
  $user_name   = undef,
  $password    = undef
) {

  #todo: check choco version from custom choco_version fact

  $_choco_exe_path = "${::choco_install_path}\\bin\\choco.exe"

  #choco source list -r
  #choco source add -r -n -s -u -p
  #choco source remove -r -n
  #choco source enable -r -n
  #choco source disable -r -n

  #if user/pass, we have to attempt to set every time to see if it is set

}
