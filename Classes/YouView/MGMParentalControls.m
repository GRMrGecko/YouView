//
//  MGMParentalControls.m
//  YouView
//
//  Created by Mr. Gecko on 4/25/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMParentalControls.h"
#import "MGMController.h"
#import "MGMAddons.h"
#import <MGMUsers/MGMUsers.h>
#import <GeckoReporter/GeckoReporter.h>
#import <CommonCrypto/CommonDigest.h>
#import <openssl/evp.h>
#import <openssl/rand.h>
#import <openssl/rsa.h>
#import <openssl/engine.h>
#import <openssl/sha.h>
#import <openssl/pem.h>
#import <openssl/bio.h>
#import <openssl/err.h>
#import <openssl/ssl.h>

NSString * const MGMKey = @"LJlmlj832jfs";
NSString * const MGMParentalPath = @".parental.plist";
NSString * const MGMMasterKey = @"PCMasterKey";

@implementation MGMParentalControls
+ (id)standardParentalControls {
	return [[[self alloc] init] autorelease];
}
- (id)init {
	if (self = [super init]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[[self path] stringByExpandingTildeInPath]]) {
			parentalControls = [[NSMutableDictionary dictionaryWithContentsOfFile:[[self path] stringByExpandingTildeInPath]] retain];
			masterKey = [[self decrypt:[[NSUserDefaults standardUserDefaults] objectForKey:MGMMasterKey] withKey:MGMKey] retain];
		} else {
			parentalControls = [NSMutableDictionary new];
			srandomdev();
			masterKey = [[[NSString stringWithFormat:@"%d", random()] MD5] retain];
			[[NSUserDefaults standardUserDefaults] setObject:[self encrypt:masterKey withKey:MGMKey] forKey:MGMMasterKey];
			[self setBool:NO forKey:MGMAllowFlaggedVideos];
			[self setString:@"moderate" forKey:MGMSafeSearch];
		}
    }
    return self;
}
- (void)dealloc {
#if releaseDebug
	MGMLog(@"%s Releasing", __PRETTY_FUNCTION__);
#endif
	[parentalControls release];
	[masterKey release];
	[super dealloc];
}

- (NSString *)path {
	return [[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMParentalPath];
}
- (NSData *)encrypt:(NSString *)string withKey:(NSString *)key {
	OpenSSL_add_all_algorithms();
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	
	unsigned char *input = (unsigned char *)[data bytes];
    unsigned char *outbuf, iv[EVP_MAX_IV_LENGTH];
    int outlen, templen, inlen;
    inlen = [data length];
    
    if(inlen==0)
        return nil;
	
	//Key
	unsigned char evp_key[EVP_MAX_KEY_LENGTH] = {"\0"};
	EVP_CIPHER_CTX cCtx;
	const EVP_CIPHER *cipher;
	
	cipher = EVP_get_cipherbyname("aes128");
	if (!cipher){
		MGMLog(@"cannot get cipher with name aes128");
		return nil;
	}
	
	EVP_BytesToKey(cipher, EVP_md5(), NULL, (unsigned char *)[key UTF8String], [key length], 1, evp_key, iv);
	EVP_CIPHER_CTX_init(&cCtx);
	
	if (!EVP_EncryptInit(&cCtx, cipher, evp_key, iv)) {
		MGMLog(@"EVP_EncryptInit() failed!");
		EVP_CIPHER_CTX_cleanup(&cCtx);
		return nil;
	}
	EVP_CIPHER_CTX_set_key_length(&cCtx, EVP_MAX_KEY_LENGTH);
	
	//Encrypt
	outbuf = (unsigned char *)calloc(inlen + EVP_CIPHER_CTX_block_size(&cCtx), sizeof(unsigned char));
	NSAssert(outbuf, @"Cannot allocate memory for buffer!");
	
	if (!EVP_EncryptUpdate(&cCtx, outbuf, &outlen, input, inlen)){
		MGMLog(@"EVP_EncryptUpdate() failed!");
		EVP_CIPHER_CTX_cleanup(&cCtx);
		return nil;
	}
	if (!EVP_EncryptFinal(&cCtx, outbuf + outlen, &templen)){
		MGMLog(@"EVP_EncryptFinal() failed!");
		EVP_CIPHER_CTX_cleanup(&cCtx);
		return nil;
	}
	outlen += templen;
	EVP_CIPHER_CTX_cleanup(&cCtx);
	NSData *returnData = [NSData dataWithBytes:outbuf length:outlen];
	free(outbuf);
	return returnData;
}

- (NSString *)decrypt:(NSData *)encryptedData withKey:(NSString *)key {
	OpenSSL_add_all_algorithms();
	unsigned char *outbuf, iv[EVP_MAX_IV_LENGTH];
    int outlen, templen, inlen;
    inlen = [encryptedData length];
    unsigned char *input = (unsigned char *)[encryptedData bytes];
	
	unsigned char evp_key[EVP_MAX_KEY_LENGTH] = {"\0"};
	EVP_CIPHER_CTX cCtx;
	const EVP_CIPHER *cipher;
	
	cipher = EVP_get_cipherbyname("aes128");
	if(!cipher)
	{
		MGMLog(@"cannot get cipher with name aes128");
		return nil;
	}
	
	EVP_BytesToKey(cipher, EVP_md5(), NULL, (unsigned char *)[key UTF8String], [key length], 1, evp_key, iv);
	EVP_CIPHER_CTX_init(&cCtx);
	
	if (!EVP_DecryptInit(&cCtx, cipher, evp_key, iv)) {
		MGMLog(@"EVP_DecryptInit() failed!");
		EVP_CIPHER_CTX_cleanup(&cCtx);
		return nil;
	}
	EVP_CIPHER_CTX_set_key_length(&cCtx, EVP_MAX_KEY_LENGTH);
	
	outbuf = (unsigned char *)calloc(inlen+32, sizeof(unsigned char));
	NSAssert(outbuf, @"Cannot allocate memory for buffer!");
	
	//Decrypt
	if (!EVP_DecryptUpdate(&cCtx, outbuf, &outlen, input, inlen)){
		MGMLog(@"EVP_DecryptUpdate() failed!");
		EVP_CIPHER_CTX_cleanup(&cCtx);
		return nil;
	}
	
	if (!EVP_DecryptFinal(&cCtx, outbuf + outlen, &templen)){
		MGMLog(@"EVP_DecryptFinal() failed!");
		EVP_CIPHER_CTX_cleanup(&cCtx);
		return nil;
	}
	
	outlen += templen;
	EVP_CIPHER_CTX_cleanup(&cCtx);
	NSString *returnString = [[[NSString alloc] initWithData:[NSData dataWithBytes:outbuf length:outlen] encoding:NSUTF8StringEncoding] autorelease];
	free(outbuf);
	return returnString;
}
- (void)setString:(NSString *)object forKey:(NSString *)key {
	[parentalControls setObject:[self encrypt:object withKey:masterKey] forKey:key];
	[self save];
}
- (NSString *)stringForKey:(NSString *)key {
	if ([parentalControls objectForKey:key]!=nil)
		return [self decrypt:[parentalControls objectForKey:key] withKey:masterKey];
	return nil;
}
- (void)setBool:(BOOL)object forKey:(NSString *)key {
	if (object)
		[parentalControls setObject:[self encrypt:@"YES" withKey:masterKey] forKey:key];
	else
		[parentalControls setObject:[self encrypt:@"NO" withKey:masterKey] forKey:key];
	[self save];
}
- (BOOL)boolForKey:(NSString *)key {
	return [[self decrypt:[parentalControls objectForKey:key] withKey:masterKey] isEqual:@"YES"];
}

- (void)save {
	[parentalControls writeToFile:[self path] atomically:YES];
}
@end
