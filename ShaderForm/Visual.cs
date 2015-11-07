using GLTools;
using OpenTK;
using OpenTK.Graphics.OpenGL;
using System;
using System.IO;

namespace ShaderForm
{
	class Visual
	{
		private int bufferQuad;
		private Shader shader;
		private Shader shaderCopy;
		private Texture surface;

		public Visual()
		{
			// Vertex positions
			float[] positions =
            {
                1.0f, -1.0f,
                1.0f, 1.0f,
                -1.0f, -1.0f,
                -1.0f, 1.0f
            };
			// Reserve a name for the buffer object.
			bufferQuad = GL.GenBuffer();
			// Bind it to the GL_ARRAY_BUFFER target.
			GL.BindBuffer(BufferTarget.ArrayBuffer, bufferQuad);
			// Allocate space for it (sizeof(positions)
			GL.BufferData(BufferTarget.ArrayBuffer
				, (IntPtr) (sizeof(float) * positions.Length), positions, BufferUsageHint.StaticDraw);

			GL.BindVertexArray(bufferQuad);
			GL.EnableClientState(ArrayCap.VertexArray);
			GL.VertexPointer(2, VertexPointerType.Float, 0, 0);
			GL.BindVertexArray(0);
			GL.BindBuffer(BufferTarget.ArrayBuffer, 0);

			GL.Disable(EnableCap.DepthTest);
			GL.ClearColor(1, 0, 0, 0);

			surface = new GLTools.Texture(1, 1);

			string sVertexShader = @"
				varying vec2 uv;
				void main() {
					gl_Position = gl_Vertex;
					uv = gl_Vertex.xy * 0.5f + 0.5f;
				}";
			string sFragmentShd = @"
			varying vec2 uv;
			uniform sampler2D tex;
			void main() {
				gl_FragColor = texture(tex, uv);
			}";
			shaderCopy = Shader.LoadFromStrings(sVertexShader, sFragmentShd);

			loadShader("");
		}

		public void update(float timeSec, int mouseX, int mouseY, bool leftButton, int width, int height)
		{
			surface = GLTools.Texture.Resize(ref surface, width, height);
			surface.BeginUpdate();

			var resolution = new Vector2(width, height);
			GL.Viewport(0, 0, width, height);
			shader.Begin();
			GL.Uniform1(shader.GetUniformLocation("iGlobalTime"), timeSec);
			GL.Uniform2(shader.GetUniformLocation("iResolution"), resolution);
			GL.Uniform3(shader.GetUniformLocation("iMouse"), new Vector3(mouseX, mouseY, leftButton ? 1.0f : 0.0f));
			GL.Clear(ClearBufferMask.ColorBufferBit);
			GL.BindVertexArray(bufferQuad);
			GL.DrawArrays(PrimitiveType.TriangleStrip, 0, 4);
			GL.BindVertexArray(0);
			shader.End();

			surface.EndUpdate();
		}

		public void loadShader(string fileName)
		{
			string sVertexShader = @"
				uniform vec2 iResolution;
				varying vec2 uv;
				out vec2 fragCoord;
				void main() {
					gl_Position = gl_Vertex;
					uv = gl_Vertex.xy * 0.5f + 0.5f;
					fragCoord = uv * iResolution;
				}";
			string sFragmentShd = @"
			varying vec2 uv;
			void main() {
				vec2 uv10 = floor(uv * 10.0f);
				if(1.0 > mod(uv10.x + uv10.y, 2.0f))
					discard;		
				gl_FragColor = vec4(1, 1, 0, 0);
			}";

			if (File.Exists(fileName))
			using (StreamReader sr = new StreamReader(fileName))
			{
				sFragmentShd = sr.ReadToEnd();
			}
			shader = Shader.LoadFromStrings(sVertexShader, sFragmentShd);
		}

		public void draw(int width, int height)
		{
			GL.Viewport(0, 0, width, height);
			surface.BeginUse();
			shaderCopy.Begin();
			GL.BindVertexArray(bufferQuad);
			GL.DrawArrays(PrimitiveType.TriangleStrip, 0, 4);
			GL.BindVertexArray(0);
			shaderCopy.End();
			surface.EndUse();
		}
	}
}
