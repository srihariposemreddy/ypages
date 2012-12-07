./rebar clean compile
rm -rf ./rel/ypages
./rebar -v generate
sh rel/ypages/bin/ypages console
