//
//  urlCheck.h
//  YouView Safari
//
//  Created by Mr. Gecko on 3/1/09.
//  Copyright 2009 Mr. Gecko's Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Safari.h"

void set_webView_resource_willSendRequest_redirectResponse_fromDataSource_dataSource_original( IMP method );
id webView_resource_willSendRequest_redirectResponse_fromDataSource_dataSource_override(id self, SEL _cmd, WebView *sender, id identifier, NSURLRequest *request, NSURLResponse *redirectResponse, WebDataSource *dataSource);