<meta charset='utf-8'>
<style type='text/css'>
    html,body{}* { padding: 0px; margin: 0px;}a:link { text-decoration: none;}p { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; vertical-align: middle;}
</style>
<meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1'>
<body bgcolor=black onload="playVideo()">
<video id="myVideo" width="100%" height="100%" preload="auto" PLAYSINLINE>
    <source src="VIDEO_FILE" type="video/mp4">
</video>
<script type="text/javascript">
			var vid = document.getElementById("myVideo");
			var isSkipped=false;
			var isPlayed=false;

            function fixSize(w,h){
                vid.width=w;
                vid.height=h;
            }

			function playVideo(){
		        //console.log("playVideo","playVideo");
		        callNative("size?w="+vid.videoWidth+"&h="+vid.videoHeight)
    			vid.play();
        		callNative("isMute?" + vid.muted);
			}

			function pauseVideo(){
				//console.log("pauseVideo","pauseVideo");
				vid.pause();
			}

			function skipVideo(){
				vid.pause();
				isSkipped=true;
				callNative("skipped");
				vid.currentTime=vid.duration*.92;
				//console.log("skipVideo","skipVideo");
			}

    		function isMute(isMute){
        		vid.muted=isMute;
        		callNative("isMute?" + vid.muted);
    		}

			function getTotalTime(){
				return vid.duration;
			}

			vid.ontimeupdate = function() {myFunction()};

			function callNative(command) {
				var iframe = document.createElement("IFRAME");
				iframe.setAttribute("src", "vast://" + command);
				document.documentElement.appendChild(iframe);
				iframe.parentNode.removeChild(iframe);
				iframe = null;
			}

			eventListener = function(e){
        		vid.addEventListener(e,function(){
            		if(e=="play"&&isPlayed){
    			       return;
            		}
            		if(e=="play"&&!isPlayed){
    			       isPlayed=true;
            		}
            		callNative(e);
				});
        	}

        	eventListener("play");
			eventListener("ended");
			eventListener("error");
			function myFunction() {
				if(!isSkipped){
					callNative("time?"+vid.currentTime);
				}
			}

</script>
<script type='text/javascript'>
    var actionDownX,actionDownY;
    var detla=10;
    var timestamp;
    var mediaView = document.getElementById("myVideo");

    mediaView.ontouchstart = function(e){
        e.preventDefault();
        timestamp=(new Date()).getTime();
        //console.log("time1"+timestamp);
        var touch = actionDownTouch = e.touches[0];
        var x=actionDownX= touch.clientX;
        var y =actionDownY= touch.clientY;
        //console.log("touchstart "+x+":"+y);
    };
    mediaView.ontouchend = function(e){
        var touch = e.changedTouches[0];
        var x = touch.clientX;
        var y = touch.clientY;
        var tempTime=(new Date()).getTime();
        //console.log("time2"+tempTime);
        if(Math.abs(x-actionDownX)<=detla&&Math.abs(y-actionDownY)<=detla&&tempTime-timestamp<500){
            callNative("click?x="+x+"&y="+y);
        }
    };
</script>
</body>
