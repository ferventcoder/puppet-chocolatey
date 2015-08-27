# == Class chocolatey::config
class chocolatey::config {
  assert_private()

  #todo: check choco version from custom choco_version fact

  $_choco_exe_path = "${chocolatey::choco_install_location}\\bin\\choco.exe"

  $_enable_autouninstaller = $chocolatey::enable_autouninstaller ? {
    false => 'disable',
    default => 'enable'
  }

  exec { "chocolatey_autouninstaller_${_enable_autouninstaller}":
    path    => $::path,
    command => "${_choco_exe_path} feature -r ${_enable_autouninstaller} -n autoUninstaller",
    unless  => "${_choco_exe_path} feature list -r | findstr /X /I /C:'autoUninstaller - [${_enable_autouninstaller}d]'",
  }
}
