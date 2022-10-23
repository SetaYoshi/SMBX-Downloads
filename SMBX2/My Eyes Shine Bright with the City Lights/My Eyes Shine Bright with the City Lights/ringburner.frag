//Read from the main texture using the regular texutre coordinates, and blend it with the tint colour.
//This is regular glDraw behaviour and is the same as using no shader.

#version 120

#include "shaders/logic.glsl"

uniform vec2 center;
uniform float radius;
uniform float alpha;

//Do your per-pixel shader logic here.
void main()
{
	vec4 c = vec4(0,0,0,0);
    float dist = abs(distance(gl_FragCoord.xy, center.xy));
    float grad = (dist - (radius - 8)) * 0.125;
    c.rgba = mix(vec4((0.9 + 0.1 * grad) * alpha,(0.7 + 0.3 * grad) * alpha,(0.3 + 0.4 * grad) * alpha,alpha), vec4(0,0,0,0), 1- and(gt(dist, radius-8), lt(dist, radius)));
	gl_FragColor = c;
}