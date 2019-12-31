AdViewVPAIDWrapper = function() {
    this._creative = getVPAIDAd();
    this.timer = null;

    AdViewVPAIDWrapper.prototype.setVpaidClient = function(vpiadClient) {
        this._vpaidClient = vpiadClient;
    }

    AdViewVPAIDWrapper.prototype.checkVPAIDInterface = function() {
        if(this._creative.handshakeVersion && typeof this._creative.handshakeVersion == "function" 
            && this._creative.initAd && typeof this._creative.initAd == "function" 
            && this._creative.startAd && typeof this._creative.startAd == "function" 
            && this._creative.stopAd && typeof this._creative.stopAd == "function"
            && this._creative.skipAd && typeof this._creative.skipAd == "function" 
            && this._creative.resizeAd && typeof this._creative.resizeAd == "function" 
            && this._creative.pauseAd && typeof this._creative.pauseAd == "function" 
            && this._creative.resumeAd && typeof this._creative.resumeAd == "function"
            && this._creative.expandAd && typeof this._creative.expandAd == "function"
            && this._creative.collapseAd && typeof this._creative.collapseAd == "function"
            && this._creative.subscribe && typeof this._creative.subscribe == "function" 
            && this._creative.unsubscribe && typeof this._creative.unsubscribe == "function") {

            return true;
        }
        return false; 
    };

    AdViewVPAIDWrapper.prototype.handshakeVersion = function (version) {
        return this._creative.handshakeVersion(version);
    }

    // Pass through for initAd - when the video player wants to call the ad 
    AdViewVPAIDWrapper.prototype.initAd = function(width, height, viewMode, desiredBitrate, creativeData, environmentVars) {
        this._creative.initAd(width, height, viewMode, desiredBitrate, creativeData, environmentVars); 
    };

    // Callback for AdPaused
    AdViewVPAIDWrapper.prototype.onAdPaused = function() {
        console.log("onAdPaused");
        this._vpaidClient.vpaidAdPaused();
    };

    // Callback for AdPlaying 
    AdViewVPAIDWrapper.prototype.onAdPlaying = function() {
        console.log("onAdPlaying");
        this._vpaidClient.vpaidAdPlaying();
    };

    // Callback for AdError 
    AdViewVPAIDWrapper.prototype.onAdError = function(message) {
        console.log("onAdError: " + message);
        this._vpaidClient.vpaidAdError(message);
    };

    // Callback for AdLog 
    AdViewVPAIDWrapper.prototype.onAdLog = function(message) {
        console.log("onAdLog: " + message);
        this._vpaidClient.vpaidAdLog(message);
    };

    // Callback for AdUserAcceptInvitation 
    AdViewVPAIDWrapper.prototype.onAdUserAcceptInvitation = function() {
        console.log("onAdUserAcceptInvitation");
        this._vpaidClient.vpaidAdUserAcceptInvitation();
    };

    // Callback for AdUserMinimize 
    AdViewVPAIDWrapper.prototype.onAdUserMinimize = function() {
        console.log("onAdUserMinimize");
        this._vpaidClient.vpaidAdUserMinimize();
    };

    // Callback for AdUserClose 
    AdViewVPAIDWrapper.prototype.onAdUserClose = function() {
        console.log("onAdUserClose");
        this._vpaidClient.vpaidAdUserClose();
    };

    // Callback for AdUserClose 
    AdViewVPAIDWrapper.prototype.onAdSkippableStateChange = function() {
        console.log("Ad Skippable State Changed to: " + this._creative.getAdSkippableState());
        this._vpaidClient.vpaidAdSkippableStateChange();
    };

    // Callback for AdUserClose 
    AdViewVPAIDWrapper.prototype.onAdExpandedChange = function() {
        console.log("Ad Expanded Changed to: " + this._creative.getAdExpanded());
        this._vpaidClient.vpaidAdExpandedChange();
    };

    // Pass through for getAdExpanded 
    AdViewVPAIDWrapper.prototype.getAdExpanded = function() {
        console.log("getAdExpanded");
        return this._creative.getAdExpanded(); 
    };

    // Pass through for getAdSkippableState 
    AdViewVPAIDWrapper.prototype.getAdSkippableState = function() {
        console.log("getAdSkippableState");
        return this._creative.getAdSkippableState(); 
    };

    // Callback for AdSizeChange 
    AdViewVPAIDWrapper.prototype.onAdSizeChange = function() {
        console.log("Ad size changed to: w=" + this._creative.getAdWidth() + " h=" + this._creative.getAdHeight());
        this._vpaidClient.vpaidAdSizeChange();
    };

    // Callback for AdDurationChange 
    AdViewVPAIDWrapper.prototype.onAdDurationChange = function() {
        // console.log("Ad Duration Changed to: " + this._creative.getAdDuration());
        this._vpaidClient.vpaidAdDurationChange();
    };

    // Callback for AdRemainingTimeChange 
    AdViewVPAIDWrapper.prototype.onAdRemainingTimeChange = function() {
        // console.log("Ad Remaining Time Changed to: " + this._creative.getAdRemainingTime());
        this._vpaidClient.vpaidAdRemainingTimeChange();
    };

    // Pass through for getAdRemainingTime 
    AdViewVPAIDWrapper.prototype.getAdRemainingTime = function() {
        return this._creative.getAdRemainingTime(); 
    };

    // Callback for AdImpression 
    AdViewVPAIDWrapper.prototype.onAdImpression = function() {
        console.log("Ad Impression");
        this._vpaidClient.vpaidAdImpression();
    };

    // Callback for AdClickThru
    AdViewVPAIDWrapper.prototype.onAdClickThru = function(url, id, playerHandles) {
        console.log("Clickthrough portion of the ad was clicked");
        var adjustedUrl = url;
        if (adjustedUrl == undefined)
            adjustedUrl = ""
        this._vpaidClient.vpaidAdClickThruIdPlayerHandles(adjustedUrl, id, playerHandles);
    };

    // Callback for AdInteraction 
    AdViewVPAIDWrapper.prototype.onAdInteraction = function(id) {
        console.log("A non-clickthrough event has occured");
        this._vpaidClient.vpaidAdInteraction(id);
    };

    // Callback for AdUserClose
    AdViewVPAIDWrapper.prototype.onAdVideoStart = function() {
        console.log("Video 0% completed");
        this._vpaidClient.vpaidAdVideoStart();
    };

    // Callback for AdUserClose
    AdViewVPAIDWrapper.prototype.onAdVideoFirstQuartile = function() {
        console.log("Video 25% completed");
        this._vpaidClient.vpaidAdVideoFirstQuartile();
    };

    // Callback for AdUserClose 
    AdViewVPAIDWrapper.prototype.onAdVideoMidpoint = function() {
        console.log("Video 50% completed");
        this._vpaidClient.vpaidAdVideoMidpoint();
    };

    // Callback for AdUserClose 
    AdViewVPAIDWrapper.prototype.onAdVideoThirdQuartile = function() {
        console.log("Video 75% completed");
        this._vpaidClient.vpaidAdVideoThirdQuartile();
    };

    // Callback for AdVideoComplete 
    AdViewVPAIDWrapper.prototype.onAdVideoComplete = function() {
        console.log("Video 100% completed");
        this._vpaidClient.vpaidAdVideoComplete();
    };

    // Callback for AdLinearChange 
    AdViewVPAIDWrapper.prototype.onAdLinearChange = function() {
        console.log("Ad linear has changed: " + this._creative.getAdLinear());
        this._vpaidClient.vpaidAdLinearChange();
    };

    // Pass through for getAdLinear 
    AdViewVPAIDWrapper.prototype.getAdLinear = function() {
        console.log("getAdLinear");
        return this._creative.getAdLinear(); 
    };

    // Pass through for getAdLinear 
    AdViewVPAIDWrapper.prototype.getAdDuration = function() {
        console.log("getAdDuration");
        return this._creative.getAdDuration(); 
    };

    // Callback for AdLoaded
    AdViewVPAIDWrapper.prototype.onAdLoaded = function() {
        console.log("ad has been loaded");
        this._vpaidClient.vpaidAdLoaded();
    };
    
    // Callback for StartAd()
    AdViewVPAIDWrapper.prototype.onAdStarted = function() {
        console.log("Ad has started");
        this.timer = setInterval(function() {
                                    this._vpaidClient.vpaidProgressChanged();
                                 }.bind(this), 500);
        this._vpaidClient.vpaidAdStarted();
    };
    
    // Callback for AdUserClose
    AdViewVPAIDWrapper.prototype.onAdStopped = function() {
        console.log("Ad has stopped");
        clearInterval(this.timer);
        this._vpaidClient.vpaidAdStopped();
    };

    // Callback for AdUserClose 
    AdViewVPAIDWrapper.prototype.onAdSkipped = function() {
        console.log("Ad was skipped");
        this._vpaidClient.vpaidAdSkipped();
    };

    //Passthrough for setAdVolume 
    AdViewVPAIDWrapper.prototype.setAdVolume = function(val) {
        this._creative.setAdVolume(val); 
    };

    //Passthrough for getAdVolume 
    AdViewVPAIDWrapper.prototype.getAdVolume = function() {
        return this._creative.getAdVolume(); 
    };

    // Callback for AdVolumeChange 
    AdViewVPAIDWrapper.prototype.onAdVolumeChange = function() {
        console.log("Ad Volume has changed to - " + this._creative.getAdVolume());
        this._vpaidClient.vpaidAdVolumeChanged();
    };

    // Pass through for startAd() 
    AdViewVPAIDWrapper.prototype.startAd = function() {
        this._creative.startAd();
    };

    // Pass through for skipAd() 
    AdViewVPAIDWrapper.prototype.skipAd = function() {
        this._creative.skipAd();
    };

    //Pass through for stopAd() 
    AdViewVPAIDWrapper.prototype.stopAd = function() {
        this._creative.stopAd(); 
    };

    //Passthrough for resizeAd 
    AdViewVPAIDWrapper.prototype.resizeAd = function(width, height, viewMode) {
        this._creative.resizeAd(width, height, viewMode);
    };

    //Passthrough for pauseAd() 
    AdViewVPAIDWrapper.prototype.pauseAd = function() {
        this._creative.pauseAd(); 
    };

    //Passthrough for resumeAd() 
    AdViewVPAIDWrapper.prototype.resumeAd = function() {
        this._creative.resumeAd(); 
    };

    //Passthrough for expandAd() 
    AdViewVPAIDWrapper.prototype.expandAd = function() {
        this._creative.expandAd(); 
    };

    //Passthrough for collapseAd() 
    AdViewVPAIDWrapper.prototype.collapseAd = function() {
        this._creative.collapseAd(); 
    };

    // This function registers the callbacks of each of the events
    AdViewVPAIDWrapper.prototype.setCallbacksForCreative = function() {
        //The key of the object is the event name and the value is a reference to the callback function that is registered with the creative
        var callbacks = {
            'AdStarted' : this.onAdStarted,
            'AdStopped' : this.onAdStopped,
            'AdSkipped' : this.onAdSkipped,
            'AdLoaded' : this.onAdLoaded,
            'AdLinearChange' : this.onAdLinearChange,
            'AdSizeChange' : this.onAdSizeChange, 
            'AdExpandedChange' : this.onAdExpandedChange, 
            'AdSkippableStateChange' : this.onAdSkippableStateChange, 
            'AdDurationChange' : this.onAdDurationChange, 
            'AdRemainingTimeChange' : this.onAdRemainingTimeChange, 
            'AdVolumeChange' : this.onAdVolumeChange,
            'AdImpression' : this.onAdImpression,
            'AdClickThru' : this.onAdClickThru,
            'AdInteraction' : this.onAdInteraction,
            'AdVideoStart' : this.onAdVideoStart,
            'AdVideoFirstQuartile' : this.onAdVideoFirstQuartile, 
            'AdVideoMidpoint' : this.onAdVideoMidpoint, 
            'AdVideoThirdQuartile' : this.onAdVideoThirdQuartile, 
            'AdVideoComplete' : this.onAdVideoComplete, 
            'AdUserAcceptInvitation' : this.onAdUserAcceptInvitation, 
            'AdUserMinimize' : this.onAdUserMinimize,
            'AdUserClose' : this.onAdUserClose,
            'AdPaused' : this.onAdPaused,
            'AdPlaying' : this.onAdPlaying,
            'AdError' : this.onAdError,
            'AdLog' : this.onAdLog
        };
        // Looping through the object and registering each of the callbacks with the creative
        for (var eventName in callbacks) { 
            this._creative.subscribe(callbacks[eventName], eventName, this); 
        }
    };

    AdViewVPAIDWrapper.prototype.onAdSkipPress = function() {
        this._creative.skipAd();
    }
}

// This class is meant to be part of the video player that interacts with the Ad. 
// It takes the VPAID creative as a parameter in its contructor. 
getVPAIDWrapper = function () {
    var wrapper = new AdViewVPAIDWrapper();
    wrapper.setCallbacksForCreative();
    return wrapper;
}