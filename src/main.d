module main;

import std.stdio;

import dagon;

class MyScene: Scene
{
    SceneApplication sceneApplication;
    
    OBJAsset aSuzanne;
    ImageAsset aHeightmap;
    TextureAsset aTexGrass;
    
    Camera camera;
    FreeviewComponent freeview;
    
    Entity model;
    float angle = 0.0f;
    
    FreeTypeFont font;
    Entity text;
    TextLine infoText;
    
    NuklearGUI gui;
    
    this(SceneApplication app)
    {
        super(app);
        sceneApplication = app;
    }
    
    override void beforeLoad()
    {
        aSuzanne = addOBJAsset("data/suzanne.obj");
        aHeightmap = addImageAsset("data/heightmap.png");
        aTexGrass = addTextureAsset("data/grass.png");
    }

    override void onLoad(Time t, float progress)
    {
    }
    
    override void afterLoad()
    {
        camera = addCamera();
        freeview = New!FreeviewComponent(eventManager, camera);
        freeview.zoom(-100);
        sceneApplication.activeCamera = camera;
        
        model = addEntity();
        model.position = Vector3f(-256, 0, -256);
        //model.drawable = aSuzanne.mesh;
        model.material = New!Material(null, assetManager);
        model.material.diffuse = aTexGrass.texture;
        model.material.textureScale = Vector2f(10.0f, 10.0f);

        auto heightmap = New!ImageHeightmap(aHeightmap.image, 30.0f, assetManager);
        auto terrain = New!Terrain(512, 64, heightmap, assetManager);
        model.drawable = terrain;
        
        gui = New!NuklearGUI(eventManager, assetManager);
        gui.addFont("data/font/DroidSans.ttf", 18, gui.localeGlyphRanges);
        auto eNuklear = addEntityHUD();
        eNuklear.drawable = gui;
        
        NKColor[] styleTable;
        styleTable = New!(NKColor[])(NK_COLOR_COUNT);
        styleTable[NK_COLOR_TEXT] = gui.rgba(70, 70, 70, 255);
        styleTable[NK_COLOR_WINDOW] = gui.rgba(175, 175, 175, 255);
        styleTable[NK_COLOR_HEADER] = gui.rgba(175, 175, 175, 255);
        styleTable[NK_COLOR_BORDER] = gui.rgba(70, 70, 70, 255);
        styleTable[NK_COLOR_BUTTON] = gui.rgba(185, 185, 185, 255);
        styleTable[NK_COLOR_BUTTON_HOVER] = gui.rgba(170, 170, 170, 255);
        styleTable[NK_COLOR_BUTTON_ACTIVE] = gui.rgba(160, 160, 160, 255);
        styleTable[NK_COLOR_TOGGLE] = gui.rgba(190, 190, 190, 255);
        styleTable[NK_COLOR_TOGGLE_HOVER] = gui.rgba(120, 120, 120, 255);
        styleTable[NK_COLOR_TOGGLE_CURSOR] = gui.rgba(70, 70, 70, 255);
        styleTable[NK_COLOR_SELECT] = gui.rgba(190, 190, 190, 255);
        styleTable[NK_COLOR_SELECT_ACTIVE] = gui.rgba(175, 175, 175, 255);
        styleTable[NK_COLOR_SLIDER] = gui.rgba(190, 190, 190, 255);
        styleTable[NK_COLOR_SLIDER_CURSOR] = gui.rgba(80, 80, 80, 255);
        styleTable[NK_COLOR_SLIDER_CURSOR_HOVER] = gui.rgba(70, 70, 70, 255);
        styleTable[NK_COLOR_SLIDER_CURSOR_ACTIVE] = gui.rgba(60, 60, 60, 255);
        styleTable[NK_COLOR_PROPERTY] = gui.rgba(190, 190, 190, 255);
        styleTable[NK_COLOR_EDIT] = gui.rgba(150, 150, 150, 255);
        styleTable[NK_COLOR_EDIT_CURSOR] = gui.rgba(0, 0, 0, 255);
        styleTable[NK_COLOR_COMBO] = gui.rgba(175, 175, 175, 255);
        styleTable[NK_COLOR_CHART] = gui.rgba(160, 160, 160, 255);
        styleTable[NK_COLOR_CHART_COLOR] = gui.rgba(45, 45, 45, 255);
        styleTable[NK_COLOR_CHART_COLOR_HIGHLIGHT] = gui.rgba( 255, 0, 0, 255);
        styleTable[NK_COLOR_SCROLLBAR] = gui.rgba(180, 180, 180, 255);
        styleTable[NK_COLOR_SCROLLBAR_CURSOR] = gui.rgba(140, 140, 140, 255);
        styleTable[NK_COLOR_SCROLLBAR_CURSOR_HOVER] = gui.rgba(150, 150, 150, 255);
        styleTable[NK_COLOR_SCROLLBAR_CURSOR_ACTIVE] = gui.rgba(160, 160, 160, 255);
        styleTable[NK_COLOR_TAB_HEADER] = gui.rgba(180, 180, 180, 255);
        gui.styleFromTable(styleTable.ptr);
        Delete(styleTable);
        
        font = New!FreeTypeFont(14, assetManager);
        font.createFromFile("data/font/DroidSans.ttf");
        font.prepareVAO();
        text = addEntityHUD();
        infoText = New!TextLine(font, "Hello, World!", assetManager);
        infoText.color = Color4f(0.27f, 0.27f, 0.27f, 1.0f);
        text.drawable = infoText;
        text.position.x = 10;
        text.position.y = eventManager.windowHeight - 10;
    }
    
    char[100] textBuffer;
    
    override void onUpdate(Time t)
    {
        model.rotation = rotationQuaternion!float(Axis.y, degtorad(angle));
        
        text.position.y = eventManager.windowHeight - 10;
        
        uint n = sprintf(textBuffer.ptr, "FPS: %u", eventManager.fps);
        string s = cast(string)textBuffer[0..n];
        infoText.setText(s);
        
        updateUserInterface(t);
    }

    override void onKeyDown(int key)
    {
        //if (key == KEY_ESCAPE)
        //    application.exit();
        if (key == KEY_BACKSPACE)
            gui.inputKeyDown(NK_KEY_BACKSPACE);
        else if (key == KEY_C && eventManager.keyPressed[KEY_LCTRL])
            gui.inputKeyDown(NK_KEY_COPY);
        else if (key == KEY_V && eventManager.keyPressed[KEY_LCTRL])
            gui.inputKeyDown(NK_KEY_PASTE);
        else if (key == KEY_A && eventManager.keyPressed[KEY_LCTRL])
            gui.inputKeyDown(NK_KEY_TEXT_SELECT_ALL);
    }
    
    override void onKeyUp(int key)
    {
        if (key == KEY_BACKSPACE)
            gui.inputKeyUp(NK_KEY_BACKSPACE);
    }
    
    override void onMouseButtonDown(int button)
    {
        gui.inputButtonDown(button);
        freeview.active = !gui.itemIsAnyActive();
    }
    
    override void onMouseButtonUp(int button)
    {
        gui.inputButtonUp(button);
    }

    override void onTextInput(dchar unicode)
    {
        gui.inputUnicode(unicode);
    }

    override void onMouseWheel(int x, int y)
    {
        freeview.active = !gui.itemIsAnyActive();
        if (!freeview.active)
            gui.inputScroll(x, y);
    }
    
    Color4f lightColor = Color4f(1.0f, 1.0f, 1.0f, 1.0f);
    float sunPitch = 0.0f;
    float sunTurn = 0.0f;
    bool option;

    void updateUserInterface(Time t)
    {
        gui.update(t);
        
        if (gui.begin("Menu", NKRect(0, 0, eventManager.windowWidth, 40), 0))
        {
            gui.menubarBegin();
            {
                gui.layoutRowStatic(30, 40, 5);

                if (gui.menuBeginLabel("File", NK_TEXT_LEFT, NKVec2(200, 200)))
                {
                    gui.layoutRowDynamic(25, 1);
                    if (gui.menuItemLabel("New", NK_TEXT_LEFT)) { }
                    if (gui.menuItemLabel("Open", NK_TEXT_LEFT)) { }
                    if (gui.menuItemLabel("Save", NK_TEXT_LEFT)) { }
                    if (gui.menuItemLabel("Exit", NK_TEXT_LEFT)) { application.exit(); }
                    gui.menuEnd();
                }
                    
                if (gui.menuBeginLabel("Edit", NK_TEXT_LEFT, NKVec2(200, 200)))
                {
                    gui.layoutRowDynamic(25, 1);
                    if (gui.menuItemLabel("Copy", NK_TEXT_LEFT)) { }
                    if (gui.menuItemLabel("Paste", NK_TEXT_LEFT)) { }
                    gui.menuEnd();
                }
                
                if (gui.menuBeginLabel("Help", NK_TEXT_LEFT, NKVec2(200, 200)))
                {
                    gui.layoutRowDynamic(25, 1);
                    if (gui.menuItemLabel("About...", NK_TEXT_LEFT)) { }
                    gui.menuEnd();
                }
            }
            gui.menubarEnd();
        }
        gui.end();
        
        if (gui.begin("Properties", NKRect(0, 40, 300, eventManager.windowHeight - 40), NK_WINDOW_TITLE))
        {
            if (gui.treePush(NK_TREE_NODE, "Output Mode", NK_MAXIMIZED))
            {
                gui.layoutRowDynamic(30, 1);
                
                sceneApplication.outputMode = 
                    gui.comboString("Color\0Normal\0Position\0Composite\0", sceneApplication.outputMode, 4, 25, NKVec2(260, 200));
                gui.treePop();
            }
            
        /*
            if (gui.treePush(NK_TREE_NODE, "Sun", NK_MINIMIZED))
            {
                gui.layoutRowDynamic(30, 1);    
                sunPitch = gui.property("Pitch:", -180f, sunPitch, 0f, 1f, 0.5f);
                sunTurn = gui.property("Turn:", -180f, sunTurn, 180f, 1f, 0.5f);
                gui.treePop();
            }
                
            if (gui.treePush(NK_TREE_NODE, "Options", NK_MINIMIZED))
            {
                gui.layoutRowDynamic(30, 2);
                if (gui.optionLabel("on", option == true)) option = true;
                if (gui.optionLabel("off", option == false)) option = false;
                gui.slider(0.0f, &angle, 365.0f, 1.0f);
                gui.treePop();
            }
                
            if (gui.treePush(NK_TREE_NODE, "Create Light", NK_MINIMIZED))
            {
                gui.layoutRowDynamic(150, 1);
                lightColor = gui.colorPicker(lightColor, NK_RGB);
                gui.layoutRowDynamic(25, 1);
                lightColor.r = gui.property("#R:", 0f, lightColor.r, 1.0f, 0.01f, 0.005f);
                lightColor.g = gui.property("#G:", 0f, lightColor.g, 1.0f, 0.01f, 0.005f);
                lightColor.b = gui.property("#B:", 0f, lightColor.b, 1.0f, 0.01f, 0.005f);
                gui.layoutRowDynamic(25, 1);
                if (gui.buttonLabel("Create"))
                {
                    writeln("clicked");
                }
                gui.treePop();
            }
                
            if (gui.treePush(NK_TREE_NODE, "Input", NK_MINIMIZED))
            {
                static int len = 4;
                static char[256] buffer = "test";
                gui.layoutRowDynamic(35, 1);
                gui.editString(NK_EDIT_FIELD, buffer.ptr, &len, 255, null);
                gui.treePop();
            }
        */
        }
        gui.end();
    }
}

class SceneApplication: Application
{
    Scene currentScene;
    Cadencer cadencer;
    
    RenderPipeline pipeline;
    
    DeferredGeometryStage stageGeom;
    DeferredDebugOutputStage stageDebug;
    RenderStage stageHUD;
    
    RenderView viewGeom;
    RenderView viewDebug;
    RenderView viewHUD;
    
    int outputMode = 3;
    
    void activeCamera(Camera camera)
    {
        viewGeom.camera = camera;
    }

    this(string[] args)
    {
        super(1280, 720, false, "Dagon NG", args);
        
        cadencer = New!Cadencer(&fixedUpdate, 60, this);
        
        pipeline = New!RenderPipeline(eventManager, this);
        
        stageGeom = New!DeferredGeometryStage(pipeline);
        viewGeom = New!RenderView(300, 0, eventManager.windowWidth - 300, eventManager.windowHeight - 40, this);
        stageGeom.view = viewGeom;
        
        stageDebug = New!DeferredDebugOutputStage(pipeline, stageGeom);
        viewDebug = New!RenderView(300, 0, eventManager.windowWidth - 300, eventManager.windowHeight - 40, this);
        viewDebug.ortho = true;
        stageDebug.view = viewDebug;
        
        stageHUD = New!RenderStage(pipeline);
        stageHUD.clear = false;
        stageHUD.defaultMaterial.depthWrite = false;
        stageHUD.defaultMaterial.culling = false;
        viewHUD = New!RenderView(0, 0, eventManager.windowWidth, eventManager.windowHeight, this);
        viewHUD.ortho = true;
        stageHUD.view = viewHUD;
        
        maximizeWindow();
        
        currentScene = New!MyScene(this);
        stageGeom.group = currentScene.spatialOpaque;
        stageHUD.group = currentScene.hud;
    }
    
    char[100] textBuffer;
    
    void fixedUpdate(Time t)
    {
        currentScene.update(t);
        stageDebug.outputMode = outputMode;
        pipeline.update(t);
    }
    
    override void onUpdate(Time t)
    {
        cadencer.update(t);
    }
    
    override void onRender()
    {
        pipeline.render();
    }
    
    override void onResize(int width, int height)
    {
        viewGeom.resize(width - 300, height - 40);
        viewDebug.resize(width - 300, height - 40);
        viewHUD.resize(width, height);
    }
}

void main(string[] args)
{
    SceneApplication app = New!SceneApplication(args);
    app.run();
    Delete(app);
    
    writeln(allocatedMemory);
}
