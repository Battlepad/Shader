using OpenTK.Graphics.OpenGL;
using System;

namespace GLTools
{
	/// <summary>
	/// Gl Texture class that allows loading from a file.
	/// </summary>
	public class Texture : IDisposable
	{
		/// <summary>
		/// Initializes a new instance of the <see cref="Texture"/> class.
		/// </summary>
		public Texture()
		{
			//generate one texture and put its ID number into the "m_uTextureID" variable
			GL.GenTextures(1, out m_uTextureID);
			Width = 0;
			Height = 0;
		}

		public void Dispose()
		{
			GL.DeleteTexture(m_uTextureID);
		}

		/// <summary>
		/// Filters the texture with a point filter.
		/// </summary>
		public void FilterBilinear()
		{
			BeginUse();
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMagFilter, (float)TextureMagFilter.Linear);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMinFilter, (float)TextureMinFilter.Linear);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.GenerateMipmap, 0);
			EndUse();
		}

		public void FilterNearest()
		{
			BeginUse();
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMagFilter, (float)TextureMagFilter.Nearest);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMinFilter, (float)TextureMinFilter.Nearest);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.GenerateMipmap, 0);
			EndUse();
		}

		/// <summary>
		/// Filters the texture with a tent filter.
		/// </summary>
		public void FilterTrilinear()
		{
			BeginUse();
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMagFilter, (float)TextureMagFilter.Linear);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMinFilter, (float)TextureMinFilter.LinearMipmapLinear);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.GenerateMipmap, 1);
			EndUse();
		}

		public void BeginUse()
		{
			GL.Enable(EnableCap.Texture2D);
			GL.BindTexture(TextureTarget.Texture2D, m_uTextureID);
		}

		public void EndUse()
		{ 
			GL.Disable(EnableCap.Texture2D);
		}

		public void LoadPixels(IntPtr pixels, int width, int height, PixelInternalFormat internalFormat, OpenTK.Graphics.OpenGL.PixelFormat inputPixelFormat)
		{
			GL.TexImage2D(TextureTarget.Texture2D, 0, internalFormat, width, height, 0,
				inputPixelFormat, PixelType.UnsignedByte, pixels);
			this.Width = width;
			this.Height = height;
		}

		public int Width { get; private set; }

		public int Height { get; private set; }

		public uint ID { get { return this.m_uTextureID; } }
	
		private readonly uint m_uTextureID = 0;
	}
}
