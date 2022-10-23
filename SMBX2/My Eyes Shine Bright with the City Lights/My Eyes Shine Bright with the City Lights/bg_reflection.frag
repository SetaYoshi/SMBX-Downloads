// Simple effect to "simulate" light refraction or whatever it's called

#version 120
uniform sampler2D iChannel0;

uniform float time;

uniform vec2 imageSize;

void main()
{
    vec2 xy = gl_TexCoord[0].xy;

    xy.x += cos(time*0.01 + xy.y*imageSize.y*0.04)*1.5 / imageSize.x;
    xy.y += cos(time*0.03 + xy.y*imageSize.y*0.08)*3.0 / imageSize.y;

    //xy.y = 1.0 - xy.y;

	vec4 c = texture2D(iChannel0, xy);
	
	gl_FragColor = c*gl_Color;
}