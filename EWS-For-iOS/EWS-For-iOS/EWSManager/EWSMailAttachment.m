//
//  EWSMailAttachment.m
//  EWS-For-iOS
//
//  Created by wangxk on 16/8/30.
//  Copyright © 2016年 wangxk. All rights reserved.
//

#import "EWSMailAttachment.h"
#import "EWSHttpRequest.h"
#import "EWSXmlParser.h"

@implementation EWSMailAttachment{
    EWSHttpRequest *request;
    NSMutableData *eData;
    EWSXmlParser *parser;
    
    NSString *currentElement;
    EWSMailAttachmentModel *_mailAttachmentModel;
}

-(instancetype)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    [self initData];
    
    return self;
}


-(void)initData{
    request = [[EWSHttpRequest alloc] init];
    eData = [[NSMutableData alloc] init];
    parser = [[EWSXmlParser alloc] init];
}


-(void)getAttachmentWithEWSUrl:(NSString *)url attachmentInfo:(EWSMailAttachmentModel *)attachmentInfo{
    _mailAttachmentModel = attachmentInfo;
    NSString *soapXmlString = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                               "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
                               "xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"\n"
                               "xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"\n"
                               "xmlns:t=\"http://schemas.microsoft.com/exchange/services/2006/types\">\n"
                               "<soap:Body>\n"
                               "<GetAttachment xmlns=\"http://schemas.microsoft.com/exchange/services/2006/messages\"\n"
                               "xmlns:t=\"http://schemas.microsoft.com/exchange/services/2006/types\">\n"
                               "<AttachmentShape>\n"
                               "<t:IncludeMimeContent>true</t:IncludeMimeContent>\n"
                               "</AttachmentShape>\n"
                               "<AttachmentIds>\n"
                               "<t:AttachmentId Id=\"%@\"/>\n"
                               "</AttachmentIds>\n"
                               "</GetAttachment>\n"
                               "</soap:Body>\n"
                               "</soap:Envelope>\n",attachmentInfo.attachmentId];
    
    [request ewsHttpRequest:soapXmlString andUrl:url receiveResponse:^(NSURLResponse *response) {
        NSLog(@"response:%@",response);
    } reveiveData:^(NSData *data) {
        [eData appendData:data];
    } finishLoading:^{
        NSLog(@"data:%@",[[NSString alloc] initWithData:eData encoding:NSUTF8StringEncoding]);
        NSLog(@"---attachment---finish-------");
        [self requestFinishLoading];
    } error:^(NSError *error) {
        NSLog(@"error:%@",error);
    }];
}

-(void)requestFinishLoading{
    [parser parserWithData:eData didStartDocument:^{
        
    } didStartElementBlock:^(NSString *elementName, NSString *namespaceURI, NSString *qName, NSDictionary *attributeDict) {
        currentElement = elementName;
    } foundCharacters:^(NSString *string) {
        [self attachmentFoundCharacters:string];
    } didEndElementBlock:^(NSString *elementName, NSString *namespaceURI, NSString *qName) {
        currentElement = nil;
    } didEndDocument:^{
        
    }];
}

-(void)attachmentFoundCharacters:(NSString *)string{
    if ([currentElement isEqualToString:@"t:Content"]) {
        NSData *xmlData = [[NSData alloc] initWithBase64EncodedString:string options:0];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *fullPathToFile = [documentsDirectory stringByAppendingPathComponent:_mailAttachmentModel.name];
        
        [xmlData writeToFile:fullPathToFile atomically:NO];
        _mailAttachmentModel.attachmentPath = fullPathToFile;
    }
    
}

@end
