uniform vec2 iResolution;
uniform float iGlobalTime;
in vec2 uv;
		
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 pos = uv - 0.5;
	pos *= 30.0;
	pos.x *= sin(iGlobalTime);
	pos.y *= sin(iGlobalTime) * cos(iGlobalTime * 0.1);
	pos += 0.5;
	pos = fract(pos);
	float a = length(pos - vec2(0.5));
	a = pow(1.0 - a, 12);
	fragColor = vec4(a * 10.0 * abs(sin(iGlobalTime * 0.5)), 2.0 * a, 5.0 * a, 1.0);	
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}
