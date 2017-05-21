# Build and test the JS target.
haxe build.hxml && 
node bin/refresh.js -js --debug test/test.prog test/test.js &&
node test/test.js