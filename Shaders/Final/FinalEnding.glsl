uniform vec3 iMouse;
uniform vec2 iResolution;
uniform float iGlobalTime;

const float epsilon = 0.0001; //TODO: smaller epsilon with bisection?
const int maxIterations = 256;
const vec3 boxPos = vec3(0.0,0.0,5.5);

//const vec3 boxPos = vec3(0.0,0.0,10.0);

struct Intersection
{
    vec3 intersectP;
    vec4 color;
    vec3 normal;
    bool exists;
};

float distSphere(vec3 p, vec3 m, float r){
    return length(p - m) - r;
}

float distBox( in vec3 p, vec3 data )
{
    return max(max(abs(p.x)-data.x,abs(p.y)-data.y),abs(p.z)-data.z);
}

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

vec3 repeat(vec3 P, vec3 b) //P ist Punkt wo man mit Marching gerade ist
{
    return mod(P,b)-b/2;
}

vec3 repeat2(vec3 P, vec3 b) //P ist Punkt wo man mit Marching gerade ist
{
    return mod(P-vec3(3.0,7.0,0.0), b)-b/2;
}

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

mat4 translationMatrix(vec3 delta)
{
    return mat4(    1.0,    0.0,    0.0,    delta.x,
                    0.0,    1.0,    0.0,    delta.y,
                    0.0,    0.0,    1.0,    delta.z,
                    0.0,    0.0,    0.0,    1.0     );
}

float distSceneReflection(vec3 point)
{
    //float distanceBox = distBox2(vec4(point.x,point.y,point.z,1.0),
       // vec3(2.0),boxPos); //      vec3(0.5),vec3(4.5,boxPosY,4.5)); 
    //globalColor = distanceBox < distancePlane ? boxColor : planeColor;
    //globalColor = boxColor;

    //globalColor = planeColor;
        vec3 b1 = vec3(5.0,3.0,5.0);
        vec3 b2 = vec3(4.5,7.3,4.2);

        //vec3 boxPos = vec3(0.0,0.0,10.0);

    float d1 = distBox(repeat((vec4(point.xyz,1.0)*translationMatrix(vec3(0.0,0.0,0.0-iGlobalTime))).xyz, b1),
        vec3(0.1,0.1,0.1));
    float d2 = distBox(repeat2((vec4(point.xyz,1.0)*translationMatrix(vec3(-iGlobalTime,iGlobalTime,0.0))).xyz, b2),
        vec3(0.1,0.1,0.1));
    return min(d1,d2);
    //return distanceBox;
}




float distScene(vec3 point)
{
    //float distanceBox = distBox2(vec4(point.x,point.y,point.z,1.0),
        //vec3(2.0),boxPos);*/ //      vec3(0.5),vec3(4.5,boxPosY,4.5)); 
    //globalColor = distanceBox < distancePlane ? boxColor : planeColor;
    //globalColor = boxColor;

    //globalColor = planeColor;
    vec3 spherePos = vec3(0.0,0.0,5.0);
    vec3 spherePosTmp = vec3(5.0,0.0,45.0);
    float distanceSphere = distSphere(vec4(point.xyz,1.0)*translationMatrix(spherePos), vec3(0.0), 0.5);
    //float distancePlanet = distSphere(vec4(point.xyz,1.0)*translationMatrix(vec3(15.0,0.0,45.0)), vec3(0.0), 10);

    float distancePlanet = opS(distSphere(vec4(point.xyz,1.0)*translationMatrix(spherePosTmp), vec3(0.0), 10.0),distSphere(vec4(point.xyz,1.0)*translationMatrix(vec3(15.0,0.0,45.0)), vec3(0.0), 10));
    //(vec4(point.xyz,1.0)*translationMatrix(0.0,0.0,5.0)).xyz
             //translation of cube
    return min(distanceSphere,distancePlanet);
}

vec3 getNormal(vec3 point)
{
    //grad of the vector (= normal)
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

Intersection rayMarch(vec3 origin, vec3 direction)
{
    Intersection intersect;
    intersect.exists = false;

    vec3 newPos = origin;
    newPos += 1.0*direction;

    float t = 1000.0;

    for(int i = 0; i <= maxIterations; i++)
    {
        t = distScene(newPos);

        if(t < epsilon)
        {
            intersect.exists = true;
            intersect.normal = getNormal(newPos);

            intersect.color = vec4(0.5,1.0,0.5,1.0);
            
            intersect.intersectP = newPos;

            return intersect;
        }
        else
        {
            newPos += t*direction;
        }
    }
    intersect.intersectP = newPos;
    intersect.color = vec4(0.0,0.0,0.0,0.0);
    return intersect;
}

Intersection rayMarchReflect(vec3 origin, vec3 direction)
{
    Intersection intersect;
    intersect.exists = false;

    vec3 newPos = origin;
    newPos += 1.0*direction;

    float t = 1000.0;

    for(int i = 0; i <= maxIterations; i++)
    {
        t = distSceneReflection(newPos);

        if(t < epsilon)
        {
            intersect.exists = true;
            intersect.normal = getNormal(newPos);

            intersect.color = vec4(1.0,i/maxIterations,0.5,1.0);
            
            intersect.intersectP = newPos;

            return intersect;
        }
        else
        {
            newPos += t*direction;
        }
    }
    intersect.intersectP = newPos;
    intersect.color = vec4(0.0,0.0,0.0,0.0);
    return intersect;
}

mat4 lookAt(vec3 eye, vec3 center, vec3 up)
{
    vec3 zaxis = normalize(center - eye);
    vec3 xaxis = normalize(cross(up, zaxis));
    vec3 yaxis = cross(zaxis, xaxis);

    mat4 matrix;
    //Column Major
    matrix[0][0] = xaxis.x;
    matrix[1][0] = yaxis.x;
    matrix[2][0] = zaxis.x;
    matrix[3][0] = 0;

    matrix[0][1] = xaxis.y;
    matrix[1][1] = yaxis.y;
    matrix[2][1] = zaxis.y;
    matrix[3][1] = 0;

    matrix[0][2] = xaxis.z;
    matrix[1][2] = yaxis.z;
    matrix[2][2] = zaxis.z;
    matrix[3][2] = 0;

    matrix[0][3] = -dot(xaxis, eye);
    matrix[1][3] = -dot(yaxis, eye);
    matrix[2][3] = -dot(zaxis, eye);
    matrix[3][3] = 1;

    return matrix;
}

void main()
{
	vec2 uv =  gl_FragCoord.xy/iResolution.x;


    float fov = 90.0;
    float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / iResolution.x;
    vec2 p = tanFov * (gl_FragCoord.xy * 2.0 - iResolution.xy);

    vec3 camP = vec4(0, 0, 5.0,1.0);//*rotationMatrix(vec3(0.0,1.0,0.0), 1)*translationMatrix(vec3(-boxPos));
    //vec3 camP = vec4(5.0, 10.0, 0.0, 1.0)*rotationMatrix(vec3(0.0,1.0,0.0), 4.0);
    vec3 camDir = normalize(vec3(p.x, p.y, 1.0));//TODO: wieder zu -1.0 machen!
    //camDir = (lookAt(camP, vec3(boxPos), vec3(0.0,1.0,0.0))*vec4(camDir.xyz, 1.0)).xyz;
    camDir = (lookAt(camP, vec3(-boxPos), vec3(0.0,1.0,0.0))*vec4(camDir.xyz, 1.0)).xyz;

    vec3 areaLightPos = vec3(0.0,10.0,-10.0);

    //vec3 dirLightPos = opTx(vec3(4.0,2.0,0.0),rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime));
    //vec3 lightDirection = opTx(vec3(-1.0,-1.0,0.0),rotationMatrix(vec3(0.0,1.0,0.0), iGlobalTime));

    Intersection intersect = rayMarch(camP, camDir);
    //Intersection reflectionIntersect2 = rayMarchReflect2(camP, camDir);


    if(intersect.exists)
    {
        Intersection reflectionIntersect = rayMarchReflect(intersect.intersectP+intersect.normal*0.01, normalize(reflect(camDir, intersect.normal)));
        if(distance(reflectionIntersect.intersectP, intersect.intersectP) > 25 && distance(reflectionIntersect.intersectP, intersect.intersectP) < 75)
        {
            gl_FragColor = intersect.color+reflectionIntersect.color;
        }
        else
        {
            gl_FragColor = intersect.color;

        }

//        gl_FragColor = mix(intersect.color, vec4(0.8,0.5,1.0,1.0), length(intersect.intersectP-camP)/50);
    }   
    /*else if(reflectionIntersect2.exists)   
    {
        gl_FragColor = reflectionIntersect2.color;
    } */
    else
    {
        //gl_FragColor = mix(vec4(0.0,0.0,0.0,0.0),fogColor, min(length(intersect.intersectP-camP)/fog,1.0));
        vec2 position = ( gl_FragCoord.xy - iResolution.xy*.5 ) / iResolution.x;

        // 256 angle steps
        float angle = atan(position.y,position.x)/(2.*3.14159265359);
        angle -= floor(angle);
        float rad = length(position);
        
        float color = 0.0;
        for (int i = 0; i < 5; i++) 
        {
            float angleFract = fract(angle*36.);
            float angleRnd = floor(angle*360.)+1.;
            float angleRnd1 = fract(angleRnd*fract(angleRnd*.7235)*45.1);
            float angleRnd2 = fract(angleRnd*fract(angleRnd*.82657)*13.724);
            float t = iGlobalTime*5.0+angleRnd1*100.;
            float radDist = sqrt(angleRnd2+float(i));
            
            float adist = radDist/rad*.1;
            float dist = (t*.2+adist);
            dist = abs(fract(dist)-.5);
            color += max(0.,.5-dist*100./adist)*(.5-abs(angleFract-.5))*5./adist/radDist;
            
            angle = fract(angle);
        }    
    gl_FragColor = vec4(color,color,color,1.0);
    //gl_FragColor = vec4(0.0,0.0,0.0,1.0);

    }
}