<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" DefaultTargets="Build" ToolsVersion="4.0">
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
        <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
        <SchemaVersion>2.0</SchemaVersion>
        <RunPostBuildEvent>OnBuildSuccess</RunPostBuildEvent>
        <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
    </PropertyGroup>
    <PropertyGroup Condition=" '$(Configuration)' == 'Debug' ">
        <DefineConstants>DEBUG;TRACE;MONO</DefineConstants>
        <OutputPath>bin\Debug\</OutputPath>
        <GeneratePDB>True</GeneratePDB>
        <GenerateMDB>True</GenerateMDB>
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
    </PropertyGroup>
    <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">
        <OutputPath>bin\Release\</OutputPath>
        <EnableAsserts>False</EnableAsserts>
        <DefineConstants>MONO</DefineConstants>
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
        <CpuType>anycpu</CpuType>
        <OutputPath>bin\Debug\</OutputPath>
        <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
        <WarnOnCaseMismatch>True</WarnOnCaseMismatch>
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
        <Reference Include="mscorlib"/>
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
        <Reference Include="System"/>
        <Reference Include="System.Core"/>
        <Reference Include="System.Data"/>
        <Reference Include="System.Windows.Forms"/>
        <Reference Include="System.Xml"/>
        <Reference Include="System.Xml.Linq"/>
        <Reference Include="Mono.Security">
            <HintPath>Mono.Security.dll</HintPath>
            <Private>True</Private>
        </Reference>
    </ItemGroup>
    <ItemGroup>
        <Compile Include="APS\ApplePushProviderService_Impl.pas">
            <SubType>Component</SubType>
            <DesignableClassName>RemObjects.SDK.Push.ApplePushProviderService</DesignableClassName>
        </Compile>
        <Compile Include="APS\APSConnect.pas"/>
        <Compile Include="DeviceManagers\FileDeviceManager.pas"/>
        <Compile Include="DeviceManagers\IDeviceManager.pas"/>
        <Compile Include="DeviceManagers\InMemoryDeviceManager.pas"/>
        <Compile Include="Events.pas"/>
        <Compile Include="GCM\Extensions.pas"/>
        <Compile Include="GCM\GCMConnect.pas"/>
        <Compile Include="GCM\GCMMessage.pas"/>
        <Compile Include="GCM\GooglePushProviderService_Impl.pas">
            <DisableDesigner>True</DisableDesigner>
            <SubType>Component</SubType>
            <DesignableClassName>RemObjects.SDK.Push.GooglePushProviderService</DesignableClassName>
        </Compile>
        <Compile Include="GCM\GCMResponse.pas"/>
        <Compile Include="Log.pas"/>
        <Compile Include="MPNS\Extensions.pas"/>
        <Compile Include="Generic\GenericPushConnect.pas"/>
        <Compile Include="IPushConnect.pas"/>
        <Compile Include="MPNS\MPNSConnect.pas"/>
        <Compile Include="MPNS\MPNSMessages.pas"/>
        <Compile Include="MPNS\MPNSResponse.pas"/>
        <Compile Include="MPNS\WindowsPhonePushProviderService_Impl.pas">
            <SubType>Component</SubType>
            <DesignableClassName>RemObjects.SDK.Push.WindowsPhonePushProviderService</DesignableClassName>
        </Compile>
        <Compile Include="PushDeviceInfo.pas"/>
        <Compile Include="Properties\AssemblyInfo.pas"/>
        <EmbeddedResource Include="Properties\Resources.resx">
            <Generator>ResXFileCodeGenerator</Generator>
        </EmbeddedResource>
        <Compile Include="Properties\Resources.Designer.pas"/>
        <None Include="Properties\Settings.settings">
            <Generator>SettingsSingleFileGenerator</Generator>
        </None>
        <Compile Include="Properties\Settings.Designer.pas"/>
        <Compile Include="PushManager.pas"/>
        <EmbeddedResource Include="PushProvider.RODL"/>
        <Compile Include="PushProvider_Intf.pas"/>
        <Compile Include="PushProvider_Events.pas"/>
        <Compile Include="PushProvider_Invk.pas"/>
    </ItemGroup>
    <ItemGroup>
        <Folder Include="DeviceManagers"/>
        <Folder Include="MPNS"/>
        <Folder Include="GCM"/>
        <Folder Include="APS"/>
        <Folder Include="Generic"/>
        <Folder Include="Properties\"/>
    </ItemGroup>
    <ProjectExtensions>
        <MonoDevelop>
            <Properties InternalTargetFrameworkVersion="3.5"/>
        </MonoDevelop>
    </ProjectExtensions>
    <Import Project="$(MSBuildExtensionsPath)/RemObjects Software/Oxygene/RemObjects.Oxygene.Echoes.targets"/>
    <PropertyGroup>
        <PreBuildEvent/>
    </PropertyGroup>
</Project>