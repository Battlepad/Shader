using GLTools;
using OpenTK;
using OpenTK.Graphics.OpenGL;
using System;
using System.IO;

namespace ShaderForm
{
	public class ShaderLoadException : Exception
	{
		public ShaderLoadException(string msg) : base(msg) { }
	}

	class Visual : IDisposable
	{
		private int bufferQuad;
		private Texture texture1;
		private Shader shader;
		private Shader shaderCopyToScreen;
		private FBO surface;

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

			surface = new GLTools.FBO(1, 1);

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
			shaderCopyToScreen = Shader.LoadFromStrings(sVertexShader, sFragmentShd);
			shader = new Shader();
			texture1 = new Texture();
		}

		public void update(float timeSec, int mouseX, int mouseY, bool leftButton, int width, int height)
		{
			if (!shader.IsLoaded()) return;
			surface = GLTools.FBO.Resize(ref surface, width, height);
			surface.BeginUpdate();

			var resolution = new Vector2(width, height);
			GL.Viewport(0, 0, width, height);
			texture1.BeginUse();
			shader.Begin();
			GL.Uniform1(shader.GetUniformLocation("iGlobalTime"), timeSec);
			GL.Uniform2(shader.GetUniformLocation("iResolution"), resolution);
			GL.Uniform3(shader.GetUniformLocation("iMouse"), new Vector3(mouseX, mouseY, leftButton ? 1.0f : 0.0f));
			GL.Clear(ClearBufferMask.ColorBufferBit);
			GL.BindVertexArray(bufferQuad);
			GL.DrawArrays(PrimitiveType.TriangleStrip, 0, 4);
			GL.BindVertexArray(0);
			shader.End();
			texture1.EndUse();

			surface.EndUpdate();
		}

		public void loadTexture(string fileName)
		{
			texture1 = TextureLoader.FromFile(fileName);
		}

		public void loadFragmentShader(string fileName)
		{
			string sVertexShader = @"
				#version 130				
				uniform vec2 iResolution;
				varying vec2 uv;
				out vec2 fragCoord;
				void main() {
					gl_Position = gl_Vertex;
					uv = gl_Vertex.xy * 0.5f + 0.5f;
					fragCoord = uv * iResolution;
				}";

			if (!File.Exists(fileName))
			{
				throw new FileNotFoundException("Could not find fragment shader file '" + fileName + "'");
			}
			try
			{
				StreamReader sr = new StreamReader(fileName);
				string sFragmentShd = sr.ReadToEnd();
				sr.Dispose();
				shader = Shader.LoadFromStrings(sVertexShader, sFragmentShd);
			}
			catch(VertexShaderCompileException e)
			{
				throw new ShaderLoadException("Vertex shader compilation failed!" + Environment.NewLine + e.Message);
			}
			catch(FragmentShaderCompileException e)
			{
				throw new ShaderLoadException("Fragment shader compilation failed!" + Environment.NewLine + e.Message);
			}
			catch (ShaderLinkException e)
			{
				throw new ShaderLoadException("Shader link failed!" + Environment.NewLine + e.Message);
			}
		}

		public void draw(int width, int height)
		{
			GL.Viewport(0, 0, width, height);
			surface.BeginUse();
			shaderCopyToScreen.Begin();
			GL.BindVertexArray(bufferQuad);
			GL.DrawArrays(PrimitiveType.TriangleStrip, 0, 4);
			GL.BindVertexArray(0);
			shaderCopyToScreen.End();
			surface.EndUse();
		}

		public void Dispose()
		{
			shader.Dispose();
			shaderCopyToScreen.Dispose();
			texture1.Dispose();
			surface.Dispose();
		}
	}
}
