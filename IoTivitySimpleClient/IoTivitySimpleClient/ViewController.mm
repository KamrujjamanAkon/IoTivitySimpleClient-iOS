//
//  ViewController.m
//  IoTivitySimpleClient
//
//  Created by Md. Kamrujjaman Akon on 1/26/17.
//
//

#import "ViewController.h"
#import "IoTvity.h"
#import "Light.h"

@interface ViewController ()

@end

@implementation ViewController

using namespace OC;
static id myView;
Light mylight;

typedef std::map<OCResourceIdentifier, std::shared_ptr<OCResource>> DiscoveredResourceMap;
DiscoveredResourceMap discoveredResources;
std::shared_ptr<OCResource> curResource;
std::mutex curResourceLock;

- (void)viewDidLoad {
    [super viewDidLoad];

    /*
     * Configuring Platform as a CLIENT
     * with connectivity IP and Low Quality of Service
     */
    PlatformConfig cfg(OC::ServiceType::InProc,
                       OC::ModeType::Client,
                       CT_ADAPTER_IP,
                       CT_ADAPTER_IP,
                       OC::QualityOfService::LowQos);

    OCPlatform::Configure(cfg);
    [self displayLog:@"Platform configured as Client"];

    myView = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) displayLog :(NSString *) msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *strMsg = [NSString stringWithFormat : @"%@\n",msg];
        NSLog(@"%@", strMsg);

        self.tfDisplayLogs.text = [self.tfDisplayLogs.text stringByAppendingString:strMsg];
        NSRange range = NSMakeRange(self.tfDisplayLogs.text.length - 1, 1);
        [self.tfDisplayLogs scrollRangeToVisible:range];
    });
}


- (IBAction)btnFindResourceAction:(id)sender {

    std::ostringstream requestURI;
    requestURI << "/oic/res?rt=core.light";
    OCPlatform::findResource("", requestURI.str(), CT_ADAPTER_IP, &foundResource);
    [self displayLog:@"Finding Resource... "];
}

void onPut(const HeaderOptions&, const OCRepresentation& rep, const int eCode)
{
    if (eCode == OC_STACK_OK || eCode == OC_STACK_RESOURCE_CHANGED)
    {
        rep.getValue(STATEKEY, mylight.m_state);
        rep.getValue(POWERKEY, mylight.m_power);
        rep.getValue(NAMEKEY, mylight.m_name);

        [myView displayLog:@"PUT request was successful"];
        [myView displayLog:[NSString stringWithFormat:@"Power : %d", mylight.m_power]];
        [myView displayLog:[NSString stringWithFormat:@"State : %d", mylight.m_state]];
    }
    else
    {
        [myView displayLog:[NSString stringWithFormat:@"onPut error!!! code : %d", eCode]];
    }
}

void putLightRepresentation(std::shared_ptr<OCResource> resource)
{
    if(resource)
    {
        [myView displayLog:@"--------------------------"];
        [myView displayLog:@"Putting light representation..."];

        mylight.m_state = true;
        mylight.m_power = 30;

        OCRepresentation rep;
        rep.setValue(STATEKEY, mylight.m_state);
        rep.setValue(POWERKEY, mylight.m_power);

        resource->put(rep, QueryParamsMap(), &onPut);
    }
}

void onGet(const HeaderOptions&, const OCRepresentation& rep, const int eCode)
{

    if(eCode == OC_STACK_OK)
    {
        rep.getValue(STATEKEY, mylight.m_state);
        rep.getValue(POWERKEY, mylight.m_power);
        rep.getValue(NAMEKEY, mylight.m_name);

        [myView displayLog:@"GET request was successful"];
        [myView displayLog:[NSString stringWithFormat:@"Resource URI : %@", [NSString stringWithUTF8String:rep.getUri().c_str()]]];
        [myView displayLog:[NSString stringWithFormat:@"Power : %d", mylight.m_power]];
        [myView displayLog:[NSString stringWithFormat:@"State : %d", mylight.m_state]];

        putLightRepresentation(curResource);
    }
    else
    {
        [myView displayLog:[NSString stringWithFormat:@"onGet error!!! code : %d", eCode]];
    }

}

void getLightRepresentation(std::shared_ptr<OCResource> resource)
{
    if(resource)
    {
        [myView displayLog:@"--------------------------"];
        [myView displayLog:@"Getting light representation..."];
        resource->get(QueryParamsMap(), &onGet);
    }
}

void foundResource(std::shared_ptr<OCResource> resource)
{

    std::string resourceURI;
    std::string hostAddress;

    std::lock_guard<std::mutex> lock(curResourceLock);
    if(discoveredResources.find(resource->uniqueIdentifier()) == discoveredResources.end())
    {
        [myView displayLog:@"Light resource found"];
        discoveredResources[resource->uniqueIdentifier()] = resource;

        if(resource)
        {
            [myView displayLog:@"--------------------------"];
            [myView displayLog:@"DISCOVERED Resource Info:"];

            resourceURI = resource->uri();
            hostAddress = resource->host();

            [myView displayLog:[NSString stringWithFormat:@"Resource URI : %@", [NSString stringWithUTF8String:resource->uri().c_str()]]];
            [myView displayLog:[NSString stringWithFormat:@"Host address of the resource : %@", [NSString stringWithUTF8String:resource->host().c_str()]]];

            [myView displayLog:@"--------------------------"];
            [myView displayLog:@"List of resource types:"];
            for(std::string resourceTypes : resource->getResourceTypes())
            {
                [myView displayLog:[NSString stringWithFormat:@"%@", [NSString stringWithUTF8String:resourceTypes.c_str()]]];
            }

            [myView displayLog:@"--------------------------"];
            [myView displayLog:@"List of resource interfaces:"];
            for(std::string resourceInterfaces : resource->getResourceInterfaces())
            {
                [myView displayLog:[NSString stringWithFormat:@"%@", [NSString stringWithUTF8String:resourceInterfaces.c_str()]]];
            }

            curResource = resource;
            getLightRepresentation(resource);
            
        }
        else
        {
            [myView displayLog:@"Invalid resource"];
        }
    }
    else
    {
        [myView displayLog:@"Light resource found AGAIN!!!"];
    }
}
@end
