<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003" ToolsVersion="4.0">
  <PropertyGroup>
    <ProductVersion>3.5</ProductVersion>
    <RootNamespace>RemObjects.SDK.Push</RootNamespace>
    <OutputType>Library</OutputType>
    <AssemblyName>RemObjects.SDK.Push</AssemblyName>
    <AllowGlobals>false</AllowGlobals>
    <AllowLegacyOutParams>false</AllowLegacyOutParams>
    <AllowLegacyCreate>false</AllowLegacyCreate>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Name>RemObjects.SDK.Push</Name>
    <ProjectGuid>{6EE56252-1979-48FA-8409-3DCED05426C3}</ProjectGuid>
    <Company />
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <SchemaVersion>2.0</SchemaVersion>
    <RunPostBuildEvent>OnBuildSuccess</RunPostBuildEvent>
    <InternalAssemblyName />
    <StartupClass />
    <DefaultUses />
    <ApplicationIcon />
    <TargetFrameworkVersion>v3.5</TargetFrameworkVersion>
    <TargetFrameworkProfile />
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)' == 'Debug' ">
    <DefineConstants>DEBUG;TRACE;MONO</DefineConstants>
    <OutputPath>bin\Debug\</OutputPath>
    <GeneratePDB>True</GeneratePDB>
    <GenerateMDB>True</GenerateMDB>
    <SuppressWarnings />
    <EnableAsserts>True</EnableAsserts>
    <CodeFlowAnalysis>True</CodeFlowAnalysis>
    <CpuType>anycpu</CpuType>
    <TreatWarningsAsErrors>False</TreatWarningsAsErrors>
    <RegisterForComInterop>False</RegisterForComInterop>
    <UseXmlDoc>False</UseXmlDoc>
    <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
    <XmlDocAllMembers>False</XmlDocAllMembers>
    <Optimize>True</Optimize>
    <WarnOnCaseMismatch>False</WarnOnCaseMismatch>
    <RunCodeAnalysis>False</RunCodeAnalysis>
    <RequireExplicitLocalInitialization>False</RequireExplicitLocalInitialization>
    <FutureHelperClassName />
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">
    <OutputPath>bin\Release\</OutputPath>
    <EnableAsserts>False</EnableAsserts>
    <DefineConstants>MONO</DefineConstants>
    <SuppressWarnings />
    <CodeFlowAnalysis>True</CodeFlowAnalysis>
    <CpuType>anycpu</CpuType>
    <TreatWarningsAsErrors>False</TreatWarningsAsErrors>
    <RegisterForComInterop>False</RegisterForComInterop>
    <UseXmlDoc>False</UseXmlDoc>
    <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
    <XmlDocAllMembers>False</XmlDocAllMembers>
    <Optimize>True</Optimize>
    <GeneratePDB>False</GeneratePDB>
    <GenerateMDB>False</GenerateMDB>
    <WarnOnCaseMismatch>False</WarnOnCaseMismatch>
    <RunCodeAnalysis>False</RunCodeAnalysis>
    <RequireExplicitLocalInitialization>False</RequireExplicitLocalInitialization>
    <FutureHelperClassName />
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
    <DebugType>none</DebugType>
    <StartMode>Project</StartMode>
    <EnableAssert>true</EnableAssert>
    <WebDebugTarget>Cassini</WebDebugTarget>
    <XmlDocWarning>WarningOnPublicMembers</XmlDocWarning>
    <RuntimeVersion>v25</RuntimeVersion>
    <GenerateMDB>True</GenerateMDB>
    <GeneratePDB>True</GeneratePDB>
    <DefineConstants>DEBUG;TRACE;MONO</DefineConstants>
    <SuppressWarnings />
    <CpuType>anycpu</CpuType>
    <OutputPath>bin\Debug\</OutputPath>
    <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
    <WarnOnCaseMismatch>True</WarnOnCaseMismatch>
    <FutureHelperClassName />
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Release|AnyCPU' ">
    <DebugType>none</DebugType>
    <StartMode>Project</StartMode>
    <RuntimeVersion>v25</RuntimeVersion>
    <WebDebugTarget>Cassini</WebDebugTarget>
    <XmlDocWarning>WarningOnPublicMembers</XmlDocWarning>
    <EnableAssert>true</EnableAssert>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="Mono.Security">
      <Private>True</Private>
    </Reference>
    <Reference Include="mscorlib">
    </Reference>
    <Reference Include="RemObjects.InternetPack">
      <HintPath>C:\Program Files (x86)\RemObjects Software\RemObjects SDK for .NET\Bin\RemObjects.InternetPack.dll</HintPath>
    </Reference>
    <Reference Include="RemObjects.SDK">
      <Private>True</Private>
      <Package>/Users/mh/Code/RemObjects Data Abstract for Mono - 6.0.46.822/RemObjects.SDK.dll</Package>
    </Reference>
    <Reference Include="RemObjects.SDK.Server">
      <Private>True</Private>
      <Package>/Users/mh/Code/RemObjects Data Abstract for Mono - 6.0.46.822/RemObjects.SDK.Server.dll</Package>
    </Reference>
    <Reference Include="RemObjects.SDK.ZLib">
      <Private>True</Private>
      <Package>/Users/mh/Code/RemObjects Data Abstract for Mono - 6.0.46.822/RemObjects.SDK.ZLib.dll</Package>
    </Reference>
    <Reference Include="System">
    </Reference>
    <Reference Include="System.Core">
    </Reference>
    <Reference Include="System.Data">
    </Reference>
    <Reference Include="System.Data.DataSetExtensions">
    </Reference>
    <Reference Include="System.Drawing">
    </Reference>
    <Reference Include="System.Windows.Forms">
    </Reference>
    <Reference Include="System.Xml">
    </Reference>
    <Reference Include="System.Xml.Linq">
    </Reference>
  </ItemGroup>
  <ItemGroup>
    <Compile Include="APS\ApplePushProviderService_Impl.pas">
      <SubType>Component</SubType>
      <DesignableClassName>RemObjects.SDK.Push.ApplePushProviderService</DesignableClassName>
    </Compile>
    <Compile Include="APS\APSConnect.pas" />
    <Compile Include="Connects\GenericPushConnect.pas" />
    <Compile Include="Connects\IPushConnect.pas" />
    <Compile Include="DeviceManagers\FileDeviceManager.pas" />
    <Compile Include="DeviceManagers\IDeviceManager.pas" />
    <Compile Include="DeviceManagers\InMemoryDeviceManager.pas" />
    <Compile Include="Events.pas" />
    <Compile Include="GCM\Extensions.pas" />
    <Compile Include="GCM\GCMConnect.pas" />
    <Compile Include="GCM\GCMMessage.pas" />
    <Compile Include="GCM\GooglePushProviderService_Impl.pas">
      <DisableDesigner>True</DisableDesigner>
      <SubType>Component</SubType>
      <DesignableClassName>RemObjects.SDK.Push.GooglePushProviderService</DesignableClassName>
    </Compile>
    <Compile Include="GCM\GCMResponse.pas" />
    <Compile Include="MPNS\MPNSConnect.pas" />
    <Compile Include="MPNS\MPNSMessages.pas" />
    <Compile Include="MPNS\MPNSResponse.pas" />
    <Compile Include="MPNS\WindowsPhonePushProviderService_Impl.pas">
      <SubType>Component</SubType>
      <DesignableClassName>RemObjects.SDK.Push.WindowsPhonePushProviderService</DesignableClassName>
    </Compile>
    <Compile Include="PushDeviceInfo.pas" />
    <Compile Include="Properties\AssemblyInfo.pas" />
    <Compile Include="Services\PushProvider_Intf.pas" />
    <Compile Include="Services\PushProvider_Invk.pas" />
    <EmbeddedResource Include="Properties\Resources.resx">
      <Generator>ResXFileCodeGenerator</Generator>
    </EmbeddedResource>
    <Compile Include="Properties\Resources.Designer.pas" />
    <None Include="Properties\Settings.settings">
      <Generator>SettingsSingleFileGenerator</Generator>
    </None>
    <Compile Include="Properties\Settings.Designer.pas" />
    <Compile Include="PushManager.pas" />
    <EmbeddedResource Include="PushProvider.RODL" />
  </ItemGroup>
  <ItemGroup>
    <Folder Include="Connects" />
    <Folder Include="DeviceManagers" />
    <Folder Include="MPNS" />
    <Folder Include="GCM" />
    <Folder Include="APS" />
    <Folder Include="Services" />
    <Folder Include="Properties\" />
  </ItemGroup>
  <ProjectExtensions>
    <MonoDevelop>
      <Properties InternalTargetFrameworkVersion="3.5" />
    </MonoDevelop>
  </ProjectExtensions>
  <Import Project="$(MSBuildExtensionsPath)\RemObjects Software\Oxygene\RemObjects.Oxygene.Echoes.targets" />
  <PropertyGroup>
    <PreBuildEvent />
  </PropertyGroup>
</Project>