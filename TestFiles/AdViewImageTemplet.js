<meta charset='utf-8'>
<style type='text/css'>html,body{}* { padding: 0px; margin: 0px;}a:link { text-decoration: none;}p { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; vertical-align: middle;}
</style>
<style>
       img{
        object-fit:contain;
        display: table-cell;
        vertical-align:middle;
        }

</style>
<body bgcolor=black>
<img id="myView" src="VIDEO_FILE" width="100%" height="100%"/>

<script type='text/javascript'>
            var actionDownX,actionDownY;
            var detla=10;
            var timestamp;
            var mediaView = document.getElementById("myView");

            function fixSize(w,h){
                mediaView.width=w;
                mediaView.height=h;
            }
            mediaView.onload = function(){
            		console.log("status","onload");
            		callNative("size?w="+mediaView.naturalWidth+"&h="+mediaView.naturalHeight);
        	}

            mediaView.ontouchstart = function(e){
                e.preventDefault();
                timestamp=(new Date()).getTime();
                console.log("time1"+timestamp);
                var touch = actionDownTouch = e.touches[0];
                var x=actionDownX= touch.clientX;
                var y =actionDownY= touch.clientY;
                console.log("touchstart "+x+":"+y);
            };
            mediaView.ontouchend = function(e){
                var touch = e.changedTouches[0];
                var x = touch.clientX;
                var y = touch.clientY;
                var tempTime=(new Date()).getTime();
                console.log("time2"+tempTime);
                if(Math.abs(x-actionDownX)<=detla&&Math.abs(y-actionDownY)<=detla&&tempTime-timestamp<500){
                    callNative("click?x="+x+"&y="+y);
                }
            };

            function callNative(command) {
				var iframe = document.createElement("IFRAME");
				iframe.setAttribute("src", "vast://" + command);
				document.documentElement.appendChild(iframe);
				iframe.parentNode.removeChild(iframe);
				iframe = null;
			}
</script>
</body>
