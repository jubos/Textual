/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|
 
 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@interface TDCFileTransferDialogTransferReceiver : NSObject <GCDAsyncSocketDelegate>
@property (nonatomic, nweak) IRCClient *associatedClient;
@property (nonatomic, assign) BOOL isHidden; // Is visible on the dialog.
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *peerNickname;
@property (nonatomic, strong) NSString *errorMessageToken;
@property (nonatomic, strong) NSString *hostAddress;
@property (nonatomic, assign) NSInteger transferPort;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, assign) TXFSLongInt totalFilesize;
@property (nonatomic, assign) TXFSLongInt processedFilesize;
@property (nonatomic, assign) TXFSLongInt currentRecord;
@property (nonatomic, strong) NSMutableArray *speedRecords;
@property (nonatomic, uweak) TDCFileTransferDialog *transferDialog;
@property (nonatomic, nweak) TDCFileTransferDialogTableCell *parentCell;
@property (nonatomic, assign) TDCFileTransferDialogTransferStatus transferStatus;
@property (nonatomic, assign, readonly) dispatch_queue_t clientDispatchQueue;
@property (nonatomic, assign, readonly) dispatch_queue_t clientSocketQueue;
@property (nonatomic, strong, readonly) GCDAsyncSocket *client;

- (void)open;

- (void)onMaintenanceTimer;
- (void)prepareForDestruction;
- (void)updateClearButton;

- (BOOL)isSender;

- (void)close;
- (void)close:(BOOL)postNotifications;
@end
