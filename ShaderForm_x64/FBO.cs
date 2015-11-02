using System.Drawing;
using OpenTK.Graphics.OpenGL;
using System;

namespace GLTools
{
	public class FBO : IDisposable
	{
		public FBO(int width, int height)
		{
			this.Width = width;
			this.Height = height;
			//generate one texture
			GL.GenTextures(1, out m_uTextureID);
			//set default parameters for filtering and clamping
			this.BeginUse();		
			GL.TexImage2D(TextureTarget.Texture2D, 0, PixelInternalFormat.Rgba8, this.Width, this.Height, 0, PixelFormat.Rgba, PixelType.UnsignedByte, IntPtr.Zero);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMinFilter, (int)TextureMinFilter.Linear);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMagFilter, (int)TextureMagFilter.Linear);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureWrapS, (int)TextureWrapMode.ClampToBorder);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureWrapT, (int)TextureWrapMode.ClampToBorder);
			this.EndUse();

			// Create a FBO and attach the texture
			GL.GenFramebuffers(1, out m_FBOHandle);
			BeginUpdate();
			GL.FramebufferTexture2D(FramebufferTarget.Framebuffer, FramebufferAttachment.ColorAttachment0, TextureTarget.Texture2D, this.m_uTextureID, 0);
			switch (GL.CheckFramebufferStatus(FramebufferTarget.Framebuffer))
			{
				case FramebufferErrorCode.FramebufferComplete:
					{
						Console.WriteLine("FBO: The framebuffer is complete and valid for rendering.");
						break;
					}
				case FramebufferErrorCode.FramebufferIncompleteAttachment:
					{
						Console.WriteLine("FBO: One or more attachment points are not framebuffer attachment complete. This could mean there’s no texture attached or the format isn’t renderable. For color textures this means the base format must be RGB or RGBA and for depth textures it must be a DEPTH_COMPONENT format. Other causes of this error are that the width or height is zero or the z-offset is out of range in case of render to volume.");
						break;
					}
				case FramebufferErrorCode.FramebufferIncompleteMissingAttachment:
					{
						Console.WriteLine("FBO: There are no attachments.");
						break;
					}
				case FramebufferErrorCode.FramebufferIncompleteDimensionsExt:
					{
						Console.WriteLine("FBO: Attachments are of different size. All attachments must have the same width and height.");
						break;
					}
				case FramebufferErrorCode.FramebufferIncompleteFormatsExt:
					{
						Console.WriteLine("FBO: The color attachments have different format. All color attachments must have the same format.");
						break;
					}
				case FramebufferErrorCode.FramebufferIncompleteDrawBuffer:
					{
						Console.WriteLine("FBO: An attachment point referenced by GL.DrawBuffers() doesn’t have an attachment.");
						break;
					}
				case FramebufferErrorCode.FramebufferIncompleteReadBuffer:
					{
						Console.WriteLine("FBO: The attachment point referenced by GL.ReadBuffers() doesn’t have an attachment.");
						break;
					}
				case FramebufferErrorCode.FramebufferUnsupported:
					{
						Console.WriteLine("FBO: This particular FBO configuration is not supported by the implementation.");
						break;
					}
				default:
					{
						Console.WriteLine("FBO: Status unknown. (yes, this is really bad.)");
						break;
					}
			}
			EndUpdate();
		}

		public void BeginUpdate()
		{
			GL.BindFramebuffer(FramebufferTarget.Framebuffer, this.m_FBOHandle);
			GL.Viewport(0, 0, this.Width, this.Height);
		}

		public void EndUpdate()
		{
			GL.BindFramebuffer(FramebufferTarget.FramebufferExt, 0);
		}

		public void BeginUse()
		{
			GL.Enable(EnableCap.Texture2D);
			GL.BindTexture(TextureTarget.Texture2D, m_uTextureID);
		}

		public void EndUse()
		{
			GL.BindTexture(TextureTarget.Texture2D, 0);
			GL.Disable(EnableCap.Texture2D);
		}

		public int Width { get; private set; }

		public int Height { get; private set; }

		private uint m_uTextureID = 0;
		private uint m_FBOHandle = 0;

		public void Dispose()
		{
			GL.DeleteTexture(this.m_uTextureID);
			GL.DeleteFramebuffers(1, ref this.m_FBOHandle);
		}

		public static FBO Resize(ref FBO surface, int width, int height)
		{
			if(width != surface.Width || height != surface.Height)
			{
				surface.Dispose();
				surface = new FBO(width, height);
			}
			return surface;
		}
	}
}
