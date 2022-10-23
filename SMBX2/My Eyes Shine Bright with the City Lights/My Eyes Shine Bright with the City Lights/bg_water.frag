// This gets the parallax effect on the water, because no way am I placing however many layers

#version 120
uniform sampler2D iChannel0;

uniform float cameraX;
uniform vec2 imageSize;

uniform float focus;
uniform float time;

const float stepThing = 12.0;

void main()
{
	vec2 xy = gl_TexCoord[0].xy;
	vec2 fullXY = xy*imageSize;

	// Calculate parallaxX
	float parallaxUseY = (floor(fullXY.y / stepThing) * stepThing) / imageSize.y;

	float depth = mix(150.0,10.0,parallaxUseY);

	float parallaxX = depth/focus + 1.0;
	parallaxX = 1.0 / (parallaxX*parallaxX);


	// Apply movement and parallax
	xy.x = mod((fullXY.x + (cameraX + time*0.5)*parallaxX),imageSize.x) / imageSize.x;


	vec4 c = texture2D(iChannel0, xy);

	c *= mix(0.15,1.0,parallaxUseY);
	
	gl_FragColor = c*gl_Color;
}