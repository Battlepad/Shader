using System;
using System.Diagnostics;
using System.IO;
using OpenTK.Graphics.OpenGL;

namespace GLTools
{
	public class ShaderException : Exception
	{
		/// <summary>
		/// Initializes a new instance of the <see cref="ShaderException"/> class.
		/// </summary>
		/// <param name="msg">The error msg.</param>
		public ShaderException(string msg) : base(msg) { }
	}

	/// <summary>
	/// Exception for vertex compilation errors
	/// </summary>
	public class VertexShaderCompileException : ShaderException
	{
		/// <summary>
		/// Initializes a new instance of the <see cref="VertexShaderCompileException"/> class.
		/// </summary>
		/// <param name="msg">The error msg.</param>
		public VertexShaderCompileException(string msg) : base(msg) { }
	}

	/// <summary>
	/// Exception for fragment shader compilation errors
	/// </summary>
	public class FragmentShaderCompileException : ShaderException
	{
		/// <summary>
		/// Initializes a new instance of the <see cref="FragmentShaderCompileException"/> class.
		/// </summary>
		/// <param name="msg">The error msg.</param>
		public FragmentShaderCompileException(string msg) : base(msg) { }
	}
	
	/// <summary>
	/// Exception for shader link errors
	/// </summary>
	public class ShaderLinkException : ShaderException
	{
		/// <summary>
		/// Initializes a new instance of the <see cref="ShaderLinkException"/> class.
		/// </summary>
		/// <param name="msg">The error msg.</param>
		public ShaderLinkException(string msg) : base(msg) { }
	}

	/// <summary>
	/// Shader class
	/// </summary>
	public class Shader : IDisposable
	{
		/// <summary>
		/// Initializes a new instance of the <see cref="Shader"/> class.
		/// </summary>
		public Shader()
		{
		}

		/// <summary>
		/// Loads vertex and fragment shaders from strings.
		/// </summary>
		/// <param name="sVertexShd_">The s vertex SHD_.</param>
		/// <param name="sFragmentShd_">The s fragment SHD_.</param>
		/// <returns>a new instance</returns>
		public static Shader LoadFromStrings(string sVertexShd_, string sFragmentShd_)
		{
			Shader shd = new Shader();
			shd.m_ProgramID = CompileLink(sVertexShd_, sFragmentShd_);
			if (!shd.IsLoaded())
			{
				shd = null;
			}
			return shd;
		}

		/// <summary>
		/// Loads vertex and fragment shaders from files.
		/// </summary>
		/// <param name="sVertexShdFile_">The s vertex SHD file_.</param>
		/// <param name="sFragmentShdFile_">The s fragment SHD file_.</param>
		/// <returns>a new instance</returns>
		public static Shader LoadFromFiles(string sVertexShdFile_, string sFragmentShdFile_)
		{
			string sVertexShd = null;
			if(!File.Exists(sVertexShdFile_))
			{
				throw new FileNotFoundException("Could not find " + sVertexShdFile_);
			}
			using (StreamReader sr = new StreamReader(sVertexShdFile_))
			{
				sVertexShd = sr.ReadToEnd();
			}
			string sFragmentShd = null;
			if (!File.Exists(sFragmentShdFile_))
			{
				throw new FileNotFoundException("Could not find " + sFragmentShdFile_);
			}
			using (StreamReader sr = new StreamReader(sFragmentShdFile_))
			{
				sFragmentShd = sr.ReadToEnd();
			}
			return LoadFromStrings(sVertexShd, sFragmentShd);
		}

		/// <summary>
		/// Begins this shader use.
		/// </summary>
		public void Begin()
		{
			if(IsLoaded()) GL.UseProgram(m_ProgramID);
		}

		/// <summary>
		/// Ends this shader use.
		/// </summary>
		public void End()
		{
			if (IsLoaded()) GL.UseProgram(0);
		}

		/// <summary>
		/// Determines whether this shader is loaded.
		/// </summary>
		/// <returns>
		///   <c>true</c> if this shader is loaded; otherwise, <c>false</c>.
		/// </returns>
		public bool IsLoaded() { return 0 != m_ProgramID; }

		public int GetUniformLocation(string name)
		{
			return GL.GetUniformLocation(m_ProgramID, name);
		}
		private int m_ProgramID = 0;

		private static string CorrectLineEndings(string input)
		{
			return input.Replace("\n", Environment.NewLine);
		}

		private static int CompileLink(string sVertexShd_, string sFragmentShd_)
		{
			int program = 0;
			int vertexObject = 0;
			int fragmentObject = 0;
			int status_code;
			if (!string.IsNullOrEmpty(sVertexShd_))
			{
				vertexObject = GL.CreateShader(ShaderType.VertexShader);
				// Compile vertex shader
				GL.ShaderSource(vertexObject, sVertexShd_);
				GL.CompileShader(vertexObject);
				GL.GetShader(vertexObject, ShaderParameter.CompileStatus, out status_code);
				if (1 != status_code)
				{
					string log = CorrectLineEndings(GL.GetShaderInfoLog(vertexObject));
					throw new VertexShaderCompileException(log);
				}
			}
			if (!string.IsNullOrEmpty(sFragmentShd_))
			{
				fragmentObject = GL.CreateShader(ShaderType.FragmentShader);
				// Compile fragment shader
				GL.ShaderSource(fragmentObject, sFragmentShd_);
				GL.CompileShader(fragmentObject);
				GL.GetShader(fragmentObject, ShaderParameter.CompileStatus, out status_code);
				if (1 != status_code)
				{
					string log = CorrectLineEndings(GL.GetShaderInfoLog(fragmentObject));
					throw new FragmentShaderCompileException(log);
				}
			}
			program = GL.CreateProgram();
			if (0 != vertexObject)
			{
				GL.AttachShader(program, vertexObject);
			}
			if (0 != fragmentObject)
			{
				GL.AttachShader(program, fragmentObject);
			}
			try
			{
				GL.LinkProgram(program);
			}
			catch (Exception)
			{
				throw new ShaderLinkException("Unknown link error!");
			}
			GL.GetProgram(program, GetProgramParameterName.LinkStatus, out status_code);
			if (1 != status_code)
			{
				string log = CorrectLineEndings(GL.GetProgramInfoLog(program));
				GL.DeleteProgram(program);
				throw new ShaderLinkException(log);
			}
			GL.UseProgram(0);
			return program;
		}

		/// <summary>
		/// Performs application-defined tasks associated with freeing, releasing, or resetting unmanaged resources.
		/// </summary>
		public void Dispose()
		{
			if (IsLoaded())
			{
				GL.DeleteProgram(m_ProgramID);
			}
		}
	}
}
