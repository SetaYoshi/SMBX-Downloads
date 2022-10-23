#version 120
uniform sampler2D iChannel0;
uniform vec2 center;
uniform float radius;
uniform vec3 inColor;
uniform vec3 outColor;


void main()
{
  vec4 c = texture2D(iChannel0, gl_TexCoord[0].xy);

  gl_FragColor = c * gl_Color;

  gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_FragColor.rgb*inColor, 1 - step(1, distance(gl_FragCoord.xy, center)/radius));
  gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_FragColor.rgb*outColor, step(1, distance(gl_FragCoord.xy, center)/radius));
}
