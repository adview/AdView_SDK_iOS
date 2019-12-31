//
//  ADVASTError.h
//  AdViewVideoSample
//
//  Created by AdView on 16/10/9.
//  Copyright © 2016年 AdView. All rights reserved.
//

// Error definitions
typedef enum {
    VASTErrorNone,
    VASTErrorXMLParse,
    VASTErrorSchemaValidation,
    VASTErrorTooManyWrappers,
    VASTErrorNoCompatibleMediaFile,
    VASTErrorNoInternetConnection,
    VASTErrorLoadTimeout,
    VASTErrorVideoFileTooBig,
    VASTErrorPlayerNotReady,
    VASTErrorPlaybackError,
    VASTErrorMovieTooShort,
    VASTErrorPlayerHung,
    VASTErrorPlaybackAlreadyInProgress,
    VASTErrorPlayerFailed,
} AdViewVastError;

