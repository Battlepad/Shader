uniform vec2 iResolution;
uniform float iGlobalTime;
float epsilon = 0.0001;
float iterations = 1000.0;

float distSphere(vec3 p, vec3 m, float r){
	return length(p - m) - r;
}

vec3 repeat(vec3 p, vec3 b){
	return mod(p, b) - (b/2);
}

float distScene(vec3 point){
	// float dist = distSphere(repeat(point, vec3(1.1,10.0, 3.0)), vec3(0.0, 0.0, 0.0), 0.5);
	float dist = distSphere(repeat(point, vec3(3.0,3.0, 3.0)), vec3(0.0, 0.0, 0.0), 0.5);
	// dist = distSphere(point, vec3(0.0, 0.0, 0.0), 0.5);
	return dist;
	// float sphere1 = distSphere((point - vec3(1.0,2.0,1.0)), vec3(0.0, 0.0, 0.0), 2.0);
	// float sphere2 = distSphere((point - vec3(0.0,0.0,0.0)), vec3(0.0, 0.0, 0.0), 2.0);
	// float sphere3 = distSphere((point - vec3(5.0,0.0,0.0)), vec3(0.0, 0.0, 0.0), 2.0);
	// return min(sphere3, max(sphere1, sphere2));
}

vec3 getNormal(vec3 point){
	float d = epsilon;
	vec3 left = point + vec3(-d, 0.0, 0.0);
	vec3 right = point + vec3(d, 0.0, 0.0);
	vec3 up = point + vec3(0.0, d, 0.0);
	vec3 down = point + vec3(0.0, -d, 0.0);
	vec3 behind = point + vec3(0.0, 0.0, d);
	vec3 before = point + vec3(0.0, 0.0, -d);

	//gradient
	vec3 gradient = vec3(distScene(right) - distScene(left),
						distScene(up) - distScene(down),
						distScene(behind) - distScene(before));
	return normalize(gradient);
}

float lambert(vec3 O, vec3 normal, float val){
	return max(val, dot(O, normal));
}

float lighting(vec3 p){
	vec3 lightPos = vec3(0.0,10.0,0.0);
	//lightPos += vec3(2 *sin(iGlobalTime), 2 * cos(iGlobalTime), 0.0);
	vec3 lightDir = normalize(lightPos-p);
	return lambert(lightDir, getNormal(p), 0.3);
	
}

struct Intersection{
	bool exists;
	vec4 color;
	vec3 position;
	vec3 normal;
};

vec3 rotZ(vec3 toRot, float angle){
	return toRot * mat3(cos(angle), -sin(angle), 0,
		sin(angle), cos(angle), 0, 0,0,1);
}

Intersection rayMarchingScene(vec3 startPosition, vec3 dir){
	Intersection intersection;
	intersection.exists = false;
	float dist = 0.0;
	intersection.position = startPosition;
	for(int i = 0.0; i < iterations; ++i){
		dist = distScene(intersection.position);
		if(dist < epsilon){ 
			// vec4 colorLighting = lighting(position)*color;
			intersection.color = vec4(0.0, 0.0, 1.0, 1.0);
			intersection.exists = true;
			intersection.normal = getNormal(intersection.position);
			break;
		}
		intersection.position += dir * dist;
	}
	return intersection;
}

void main(){
	
	float fov = 45.0;
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
	//Fog
	vec4 fogColor = vec4(0.0, 0.5, 1.0, 1.0);
	float fogValue = 100.0;
	//Color
	// vec4 color = vec4(0.0, 0.0, 1.0, 1.0);
	vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

	//Camera
	// vec3 camP = vec3(0.0, 0.0, 0.0);
	vec3 camP = vec3(sin(iGlobalTime), 0.0, 0.0);
	//camP += vec3(2 *sin(iGlobalTime), 2 * cos(iGlobalTime), 5.0);
	vec3 camDir = normalize(vec3(p.x, p.y, 1.0));

	//Camera rotation
	//camDir = rotZ(camDir, iGlobalTime);
	
	vec4 color = vec4(0.0);

	Intersection intersection = rayMarchingScene(camP, camDir);
	if(intersection.exists){
		vec4 colorLighting = lighting(intersection.position)*intersection.color;
		
		gl_FragColor = colorLighting;

		//Reflection
		vec3 reflectedRay = normalize(reflect(camDir, intersection.normal));
		Intersection intersectionReflection = rayMarchingScene(intersection.position + intersection.normal * epsilon, reflectedRay);

		if(intersectionReflection.exists){
			vec4 colorReflectionLighting = lighting(intersectionReflection.position)* intersectionReflection.color;
			gl_FragColor = mix(colorLighting+colorReflectionLighting*0.6, fogColor, 
											length(camP-intersection.position)/fogValue);
		}else{
			gl_FragColor = mix(color, fogColor, length(camP-intersection.position)/fogValue);
		}
	}else{
 		gl_FragColor = mix(color, fogColor, length(camP-intersection.position)/fogValue);
	}
}