use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => repeat_each() * (blocks() * 2); 

my $pwd = cwd();

$ENV{TEST_LEDGE_REDIS_DATABASE} ||= 1;

our $HttpConfig = qq{
	lua_package_path "$pwd/../lua-resty-rack/lib/?.lua;$pwd/lib/?.lua;;";
	init_by_lua "
		ledge_mod = require 'ledge.ledge'
        ledge = ledge_mod:new()
		ledge:config_set('redis_database', $ENV{TEST_LEDGE_REDIS_DATABASE})
	";
};

run_tests();

__DATA__
=== TEST 1: Single line comments removed
--- http_config eval: $::HttpConfig
--- config
location /esi_1 {
    content_by_lua '
        ledge:bind("response_ready", ledge.do_esi)
        ledge:run()
    ';
}
location /__ledge_origin {
    content_by_lua '
        ngx.print("<!--esiCOMMENTED-->")
    ';
}
--- request
GET /esi_1
--- response_body: COMMENTED


=== TEST 2: Multi line comments removed
--- http_config eval: $::HttpConfig
--- config
location /esi_2 {
    content_by_lua '
        ledge:bind("response_ready", ledge.do_esi)
        ledge:run()
    ';
}
location /__ledge_origin {
    content_by_lua '
        ngx.print("<!--esi")
        ngx.print("1")
        ngx.say("-->")
        ngx.say("2")
        ngx.say("<!--esi")
        ngx.say("3")
        ngx.print("-->")
    ';
}
--- request
GET /esi_2
--- response_body
1
2

3


=== TEST 3: Single line <esi:remove> removed.
--- http_config eval: $::HttpConfig
--- config
location /esi_3 {
    content_by_lua '
        ledge:bind("response_ready", ledge.do_esi)
        ledge:run()
    ';
}
location /__ledge_origin {
    content_by_lua '
        ngx.print("<esi:remove>REMOVED</esi:remove>")
    ';
}
--- request
GET /esi_3
--- response_body


=== TEST 4: Multi line <esi:remove> removed.
--- http_config eval: $::HttpConfig
--- config
location /esi_4 {
    content_by_lua '
        ledge:bind("response_ready", ledge.do_esi)
        ledge:run()
    ';
}
location /__ledge_origin {
    content_by_lua '
        ngx.say("1")
        ngx.say("<esi:remove>")
        ngx.say("2")
        ngx.say("</esi:remove>")
        ngx.say("3")
    ';
}
--- request
GET /esi_4
--- response_body
1

3


=== TEST 5: Include fragment
--- http_config eval: $::HttpConfig
--- config
location /esi_5 {
    content_by_lua '
        ledge:bind("response_ready", ledge.do_esi)
        ledge:run()
    ';
}
location /fragment_1 {
    echo "FRAGMENT";
}
location /__ledge_origin {
    content_by_lua '
        ngx.say("1")
        ngx.print("<esi:include src=\\"/fragment_1\\" />")
        ngx.say("2")
    ';
}
--- request
GET /esi_5
--- response_body
1
FRAGMENT
2


=== TEST 6: Include multiple fragments, in correct order.
--- http_config eval: $::HttpConfig
--- config
location /esi_6 {
    content_by_lua '
        ledge:bind("response_ready", ledge.do_esi)
        ledge:run()
    ';
}
location /fragment_1 {
    content_by_lua '
        ngx.print("FRAGMENT_1")
    ';
}
location /fragment_2 {
    content_by_lua '
        ngx.print("FRAGMENT_2")
    ';
}
location /fragment_3 {
    content_by_lua '
        ngx.print("FRAGMENT_3")
    ';
}
location /__ledge_origin {
    content_by_lua '
        ngx.say("<esi:include src=\\"/fragment_3\\" />")
        ngx.say("<esi:include src=\\"/fragment_1\\" />")
        ngx.say("<esi:include src=\\"/fragment_2\\" />")
    ';
}
--- request
GET /esi_6
--- response_body
FRAGMENT_3
FRAGMENT_1
FRAGMENT_2

