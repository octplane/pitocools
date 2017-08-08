package = "pitocools"
version = "0.0.1-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "MIT"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
    ["pitocools.build"] = "pitocools/build.lua",
    ["pitocools.extract"] = "pitocools/extract.lua",
    ["pitocools.applescript"] = "pitocools/applescript.lua"

   },
   install = {
     bin = {
       ["pitocools"] = "pitocools.lua"
     }
   }
}
