//uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
in vec2 uv;
		
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float a = 1.0 - length(uv - vec2(0.5) + 0.5 * vec2(sin(iGlobalTime), cos(iGlobalTime)));
	a = pow(a, 8);
	fragColor = vec4(a, a, a, 1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}
