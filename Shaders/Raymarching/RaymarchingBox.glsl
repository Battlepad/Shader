uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;
varying vec2 uv;

float time=iGlobalTime;

const float epsilon = 0.001;
const int maxIterations = 96;

vec3 repeat(vec3 P, vec3 b) //P ist Punkt wo man mit Marching gerade ist
{
	return mod(P,b)-1.0/2.0*b;
}

float distBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float distanceBox(vec3 _point)
{
	vec3 boxPos = vec3(0.0,0.0,0.0);
	vec3 boxSize = vec3(0.3,0.2,0.2);
	vec3 b = vec3(1.0,1.0,0.0);
	vec3 point = repeat(_point, b);
	return distBox(point, boxSize);
}



float distSphere(vec3 origin, vec3 middle, float r)
{
    return length(origin - middle) - r;
}

float distance(vec3 point)
{
	vec3 spherePos = vec3(0.0,0.0,0.0);
	float radius = 0.100;
	vec3 b = vec3(2.0,3.0,2.0);
	point = repeat(point, b);
	return distSphere(point, spherePos, radius);
}

vec3 getNormal(vec3 point)
{
	return vec3(distance(point + vec3(epsilon,0.0,0.0)) - distance(point + vec3(-epsilon,0.0,0.0)),
				distance(point + vec3(0.0,epsilon,0.0)) - distance(point + vec3(0.0,-epsilon,0.0)),
				distance(point + vec3(0.0,0.0,epsilon)) - distance(point + vec3(0.0,0.0,-epsilon)));
}

void main()
{
	float fov = 70.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	vec3 camP = vec3(0.0, 0.0, -3.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	vec3 lightPos = vec3(1.0*sin(iGlobalTime), 0.0, 0.0);

	float t = 10000.0;

	vec3 newPos = camP;

	for(int i = 0; i <= maxIterations; i++)
	{
		t = distanceBox(newPos);
		newPos = newPos + camDir*t;
		if(t <= epsilon) 
		{
			vec3 normal = normalize(getNormal(newPos));
			vec4 color = vec4(0.5,1.0,1.0,1.0);
			gl_FragColor = color*max(0.2, dot(normal, normalize(lightPos-newPos)));
			return;
		}
		else
			gl_FragColor = vec4(0.0,0.0,0.0,0.0);

	}		
	

}


