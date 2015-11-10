//uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex;
in vec2 uv;
		
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec3 color = texture(tex, uv).rgb;
	fragColor = vec4(color, 1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}
