uniform vec2 iResolution;
uniform float iGlobalTime;

#define M_PI 3.1415926535897932384626433832795

struct Ray
{
    vec3 origin;
    vec3 direction;
};

struct Sphere
{
    vec3 position;
    float radius;
    vec4 color;
};

float calcT(Ray r, Sphere s)
{
    float first = dot(-r.direction,(r.origin-s.position));

    float second = pow(dot(r.direction,r.origin-s.position),2);
    float third = dot(r.direction,r.direction);
    float fourth = dot((r.origin-s.position),(r.origin-s.position))-dot(s.radius,s.radius);

    float rootContent = second - third * fourth;
    if(rootContent < 0)
    {
        return 1.0/0.0;
    }
    else
    {
        float squareRoot = sqrt (rootContent);
        float firstFinal = first+squareRoot;
        float secondFinal = first-squareRoot;
        float tmp = 1.0/0.0;
        if(firstFinal < secondFinal && firstFinal > 0)
        {
            return firstFinal;
        }
        if(secondFinal < firstFinal && secondFinal > 0)
        {
            return secondFinal;
        }

    }
}

vec4 intersect(Ray ray)
{
    float t = 1.0/0.0;
    vec4 resultColor = vec4(0.0,0.0,0.0,1.0);
    float tTmp;

    Sphere sphere;
    sphere.position = vec3(-10.0,0.0,12.0);
    sphere.radius = 1.0;
    sphere.color = vec4(1.0,0.2,0.2,1.0);

    for(int i=0; i<10; i++)
    {
        sphere.position = vec3(sphere.position.x+2.0, sphere.position.y+sin(i*iGlobalTime), sphere.position.z);
        sphere.color = vec4(sphere.color.x-0.05, sphere.color.y, sphere.color.z, 1.0);
        tTmp = calcT(ray, sphere);

        if(tTmp < t)
        {
            t = tTmp;
            resultColor = sphere.color;
        }
    }
    return resultColor;


    
    //if(firstFinal < 0)
    //{
    //    fragColor = vec4(1.0,0.5,0.5,1.0);
    //}
    //else
    //{
     //   fragColor = vec4(0.0,0.0,0.0,1.0);
    //}
    //if(rootContent < 0)
    //{
    //    return
    //}
    //else
    //{
        
   // }
   //float final = first + second-third*fourth;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	//vec2 uv = fragCoord.xy / iResolution.xy;
    //vec2 middle = iResolution.xy;
    
    float fov = 70*M_PI/180;

    vec2 p = (2.0*gl_FragCoord.xy-iResolution.xy)/iResolution.x;

    Ray ray;
    ray.origin = vec3(0.0, 0.0, 0.0);
    ray.direction = vec3(p.x, p.y, 1);
    ray.direction = normalize(ray.direction);

    fragColor = intersect(ray);
    //if(result < 0)
    //{
    //    fragColor = vec4(0.0,0.0,0.0,1.0);
   // }
    //else
    // {
    //     fragColor = vec4(1.0,0.5,0.5,1.0);
    // }
    //ray.normalize();
    //image[i][j] = intersect(ray);
}

void main()
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}