# Build and test the JS target.
haxe build.hxml && 
node bin/refresh.js -js -t3 test/test.prog test/test.js &&
node test/test.js