//
//  urlCheck.m
//  YouView Safari
//
//  Created by Mr. Gecko on 3/1/09.
//  Copyright 2009 Mr. Gecko's Media. All rights reserved.
//

#import "urlCheck.h"
#import "BundleController.h"
#import <objc/objc-runtime.h>

static IMP webView_resource_willSendRequest_redirectResponse_fromDataSource_dataSource_original;
static IMP webView_didFinishLoadForFrame_original;

void set_webView_resource_willSendRequest_redirectResponse_fromDataSource_dataSource_original( IMP method )
{
	webView_resource_willSendRequest_redirectResponse_fromDataSource_dataSource_original = method;
}

void set_webView_didFinishLoadForFrame_original(IMP method)
{
	webView_didFinishLoadForFrame_original = method;
}

NSString *getParameterWithName(NSString *name, NSString *Parameters) {
	NSArray *parameters = [Parameters componentsSeparatedByString:@"&"];
	int i;
	for (i=0; i<[parameters count]; i++) {
		NSArray *parameter = [[parameters objectAtIndex:i] componentsSeparatedByString:@"="];
		if ([[parameter objectAtIndex:0] isEqualToString:name])
			return [[parameter objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	return nil;
}

id webView_resource_willSendRequest_redirectResponse_fromDataSource_dataSource_override(id self, SEL _cmd, WebView *sender, id identifier, NSURLRequest *request, NSURLResponse *redirectResponse, WebDataSource *dataSource) {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![defaults boolForKey:@"YVDisabled"] && [request URL] && ![[[[[sender mainFrame] dataSource] request] URL] isEqualTo:[request URL]]) {
        NSString *url = [[request URL] absoluteString];
		if ([url rangeOfString:@"youtube.com/watch?"].location!=NSNotFound) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"youview://?id=%@", getParameterWithName(@"v", [[request URL] query])]]];
			return [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
		} else if ([url rangeOfString:@"youtu.be"].location!=NSNotFound) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"youview://?id=%@", [[[request URL] path] lastPathComponent]]]];
			return [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
		}
	}
	return webView_resource_willSendRequest_redirectResponse_fromDataSource_dataSource_original(self, _cmd, sender, identifier, request, redirectResponse, dataSource);
}