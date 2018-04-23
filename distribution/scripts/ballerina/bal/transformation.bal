import ballerina/http;
import ballerina/math;

type Product {
    int id;
    string name;
    float price;
};

endpoint http:Listener storeServiceEndpoint {
    port:9090
};

@http:ServiceConfig {
    basePath:"/HelloWorld"
}
service HelloWorld bind storeServiceEndpoint {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/sayHello"
    }
    sayHello(endpoint outboundEP, http:Request req) {

        json payload = check req.getJsonPayload();
        xml xmlPayload = check payload.toXML({});

        http:Response res = new;
        res.setXmlPayload(xmlPayload);
        _ = outboundEP -> respond(res);
    }
}