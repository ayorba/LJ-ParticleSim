import std.random;

// Third-party libraries
import bindbc.sdl;

Random rnd;
shared static this(){
	auto rnd = Random(42078);
}

struct Particle{

	SDL_Texture* mTexture;
	SDL_FRect     mRectangle;

	float xpos;
	float ypos;

	float xvel;
	float yvel;

	float xforce;
	float yforce;

	float mass;

	float xaccel;
	float yaccel;
	
	float radius;

	this(SDL_Renderer* renderer, string bitmapFilePath){
		import std.string; // for toZString
		// Create a texture
		SDL_Surface* mSurface = SDL_LoadBMP(bitmapFilePath.toStringz);
		mTexture = SDL_CreateTextureFromSurface(renderer,mSurface);
		SDL_DestroySurface(mSurface);
	}

	// Destroy anything 'heap' allocated.
	// Remember, SDL is a C library, thus heap allocated resources need
	// to be destroyed
	~this(){
		SDL_DestroyTexture(mTexture);
	}

	void Input(){}

	void Update(){	
				if(mRectangle.x > 620){mRectangle.x=0;}
				if(mRectangle.x < 0){mRectangle.x=620;}
				if(mRectangle.y > 460){mRectangle.y=0;}
				if(mRectangle.y < 0){mRectangle.y=460;}
	}

	void Render(SDL_Renderer* renderer){
        // Color for the rectangles
        SDL_SetRenderDrawColor(renderer, 0xFF,0x00,0x00,0xFF);
        // Render the rectangle around the particle
        // SDL_RenderRect(renderer, &mRectangle);

				// Copy a texture (or portion of a texture) to another
				// portion of video memory (i.e. a 2D grid of texels 
				// which span the width and height of the window)
				SDL_RenderTexture(renderer,mTexture,null,&mRectangle);
	}

	void SetPosition(float x, float y){
		xpos=x;
		ypos=y;
		mRectangle.x = cast(int) (x);
		mRectangle.y = cast(int) (y);
	}

	void SetVelocity(float vx, float vy) {
		xvel = vx;
		yvel = vy;
	}

	void SetRadius(float rad) {
		radius = rad;
		mRectangle.w = 2*rad;
		mRectangle.h = 2*rad;
	}

	void SetMass(float m) {
		mass = m;
	}

	void SetForce(float fx, float fy) {
		xforce = fx;
		yforce = fy;
	}

	void SetAccel(float ax, float ay) {
		xaccel=ax;
		yaccel=ay;
	}
}
