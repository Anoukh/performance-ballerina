import ballerina/http;
import ballerina/math;
import ballerina/io;

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

        table<Product> dt = table{};

        foreach x in [1.. 999] {
            Product p1 = {id:x, name:"Apple " + "iPhone " + "X", price:(math:getExponent(math:sqrt(x)))};
            io:println(p1);
            _ = dt.add(p1);
        }

        xml xmlRet = check <xml> dt;
        xml copyOfXml = xmlRet.copy();
        xml stripedXml = xmlRet.strip();

        json jsonRet = stripedXml.toJSON({attributePrefix:"@", preserveNamespaces:false});
        http:Response res = new;
        res.setJsonPayload(jsonRet);
        _ = outboundEP -> respond(res);
    }
}