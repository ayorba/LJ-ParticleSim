// Adapted From an SDL project template by Mike Shah, Ph.D.
// https://github.com/MikeShah/AppliedGeometry/tree/main/01_d_and_sdl/sdl3_template_project
	
module particle_sim;
// Import D standard libraries
import std.stdio, std.string;

import std.datetime.stopwatch;
import std.math : sqrt;
import std.math : pow;
import std.math : abs;

// Third-party libraries
import bindbc.sdl;

// Import our SDL Abstraction
import sdl_abstraction;
import particle;

struct ParticleSim{
		SDL_Window* mWindow = null;
		SDL_Renderer* mRenderer = null;
		bool mGameIsRunning = true;

		// Game Data
		Particle[81] simParticles;

		float sigma = 40.0f;
		float epsilon=8000;
		float vmag = 360;
		int window_width = 1200;
		int window_height = 900;
		int border_thickness = 20;
		float damping;

		int width;
		int height;

		float r_cutoff;
		float r2_cutoff;
		float u_of_rc;
		float uprime_of_rc;

		float dt = 0.001f;

		// Constructor
		this(string title){
				// Create an SDL window
				mWindow = SDL_CreateWindow(title.toStringz, window_width, window_height, SDL_WINDOW_ALWAYS_ON_TOP);

				// Create a hardware accelerated mRenderer
				mRenderer = SDL_CreateRenderer(mWindow,null);
				// Load the bitmap surface
				width = window_width - border_thickness;
				height = window_height - border_thickness;
				r_cutoff=3*sigma;
				r2_cutoff = r_cutoff * r_cutoff;
				u_of_rc = lj_potential(r_cutoff);
				uprime_of_rc = lj_prime(r_cutoff);
				damping = 0.2f;

				import std.random;
				auto rnd = Random(42);
				for(size_t i=0; i < simParticles.length; ++i){
					simParticles[i] = Particle(mRenderer,"./assets/images/earth.bmp");

					auto xstart = (i%9) * (width / 9);
					auto ystart = ((i / 9) * height / 9) % height;

					auto randx = cast(float) uniform(0, width, rnd);
					auto randy = cast(float) uniform(0, height, rnd);

					auto xvel = uniform(-vmag,vmag,rnd);		
					auto yvel = uniform(-vmag,vmag,rnd);

					simParticles[i].SetPosition(xstart,ystart);
					simParticles[i].SetVelocity(xvel, yvel);
					simParticles[i].SetMass(1.0f);
					simParticles[i].SetRadius(sigma / 2);
					simParticles[i].SetForce(0.0f, 0.0f);
					simParticles[i].SetAccel(0.0f,0.0f);
				}
		}

		// Destructor
		~this(){
				// Destroy our renderer
				SDL_DestroyRenderer(mRenderer);
				// Destroy our window
				SDL_DestroyWindow(mWindow);
		}

		// Handle input - no input
		void Input(){
				SDL_Event event;
				// Start our event loop
				while(SDL_PollEvent(&event)){
						// Handle each specific event
						if(event.type == SDL_EVENT_QUIT){
								mGameIsRunning= false;
						}
				}
			for(size_t i=0; i < simParticles.length; ++i){
				simParticles[i].Input();
			}
		}

		// will need to change based on forces and velocities
		void Update(){
			velocity_verlet_integrate();
		}

		// can stay the exact same
		void Render(){
				// Set the render draw color 
				SDL_SetRenderDrawColor(mRenderer,100,190,255,SDL_ALPHA_OPAQUE);
				// Clear the renderer each time we render
				SDL_RenderClear(mRenderer);

				for(size_t i=0; i < simParticles.length; ++i){
					simParticles[i].Render(mRenderer);
				}

				// Final step is to present what we have copied into
				// video memory
				SDL_RenderPresent(mRenderer);
		}

		// Advance world one frame at a time
		void AdvanceFrame(){
        	int wait_time_msec;
			auto sw = StopWatch(AutoStart.no);
			sw.start();

			Input();
			
			// Calculating force calculation and verlet integration are done here
			Update();

			// Draw the new particle positions
			Render();

			sw.stop();

			long physics_time_msec = sw.peek.total!"msecs";
			wait_time_msec = cast(int) (1000 * dt) - cast(int) physics_time_msec;
			if (wait_time_msec > 0) {
				SDL_Delay(wait_time_msec);  
				// Delay dt minus the time it took to do the physics
				// to approximate a 60 FPS game loop
			}
		}

		void RunLoop(){
				// Main application loop
				while(mGameIsRunning){
						AdvanceFrame();	
				}
		}

		void velocity_verlet_integrate(){
			// First half of velocity update using a(t)
			foreach(ref particle; simParticles) {
				
				particle.SetVelocity(particle.xvel + .5 * particle.xaccel * dt, particle.yvel + .5 * particle.yaccel * dt);

				particle.SetPosition(particle.xpos + particle.xvel * dt, particle.ypos + particle.yvel * dt);
			}

			update_forces();
			// update_gravity();

			foreach(ref particle; simParticles) {
				particle.SetAccel((particle.xforce - particle.xvel * damping) / particle.mass, (particle.yforce - particle.yvel * damping) / particle.mass);

				particle.SetVelocity(particle.xvel + .5 * particle.xaccel * dt, particle.yvel + .5 * particle.yaccel * dt);
				// reflective boundary conditions
				if (particle.xpos + particle.radius > width) {
					particle.xvel = - abs(particle.xvel);
				}
				else if (particle.xpos < 0) {
					particle.xvel = abs(particle.xvel);
				}
				if (particle.ypos + particle.radius > height) {
					particle.yvel = - abs(particle.yvel);
				}
				else if (particle.ypos < 0) {
					particle.yvel = abs(particle.yvel);
				}
				// periodic boundary conditions
				// particle.SetPosition(particle.xpos % 620, particle.ypos % 460);
			}


		}

		// update the forces on all particles
		void update_forces() {
			foreach (i, ref anchor; simParticles)
			{
				float fx = 0.0f;
				float fy = 0.0f;

				foreach (j, ref neighbor; simParticles)
				{
					if (i == j)
						continue;

					float dx = neighbor.xpos - anchor.xpos;
					float dy = neighbor.ypos - anchor.ypos;
					float dr2 = dx * dx + dy * dy;
					
					if (dr2 <= 1.0f || dr2 >= r2_cutoff)
						continue;

					float dr = sqrt(dr2);

					float fmag = lj_prime_r2(dr2) - uprime_of_rc;

					fx += fmag * dx / dr;
					fy += fmag * dy / dr;
				}

				anchor.SetForce(fx, fy);
			}
		}

		// update the forces on all particles
		void update_gravity() {
			foreach (i, ref anchor; simParticles)
			{
				float fx = 0.0f;
				float fy = 0.0f;

				foreach (j, ref neighbor; simParticles)
				{
					if (i == j)
						continue;

					float dx = neighbor.xpos - anchor.xpos;
					float dy = neighbor.ypos - anchor.ypos;
					float dr2 = dx * dx + dy * dy;
					
					if (dr2 <= 1.0f) {
						continue;
					}

					float dr = sqrt(dr2);

					float fmag = 100_000* anchor.mass * neighbor.mass / dr2;

					fx += fmag * dx / dr;
					fy += fmag * dy / dr;
				}
				anchor.SetForce(fx, fy);
			}
		}

	    float lj_potential(float dr) {

			float sigma_over_r2 = sigma * sigma / dr / dr;
			float sigma_over_r6 = sigma_over_r2 * sigma_over_r2 * sigma_over_r2;
			return 4 * epsilon * (sigma_over_r6*sigma_over_r6 - sigma_over_r6);
		}

		float lj_prime(float dr) {

			float sigma_over_r2 = (sigma * sigma / dr / dr);
			float sigma_over_r6 = sigma_over_r2 * sigma_over_r2 * sigma_over_r2;
			return 24 * epsilon / dr * (sigma_over_r6 - 2 * sigma_over_r6*sigma_over_r6);
		}

		float shifted_lj_potential(float dr){

			float sigma_over_r2 = (sigma * sigma / dr / dr);
			float sigma_over_r6 = sigma_over_r2 * sigma_over_r2  * sigma_over_r2;
			return 4 * epsilon * (sigma_over_r6*sigma_over_r6 - sigma_over_r6) - u_of_rc - (dr - r_cutoff) * uprime_of_rc;
		}

		float shifted_lj_potential_r2(float dr2){

			float sigma_over_r2 = (sigma * sigma / dr2);
			float sigma_over_r6 = sigma_over_r2 * sigma_over_r2  * sigma_over_r2;

			return 4 * epsilon * (sigma_over_r6*sigma_over_r6 - sigma_over_r6) - u_of_rc - (sqrt(dr2) - r_cutoff) * uprime_of_rc;
		}
		float shifted_lj_force(float dr) {
			return - (lj_prime(dr) - uprime_of_rc);
		}
		
		float lj_prime_r2(float dr2) {

			float sigma_over_r2 = sigma*sigma / dr2;
			float sigma_over_r6 = sigma_over_r2 * sigma_over_r2  * sigma_over_r2;
			return 24 * epsilon / sqrt(dr2) * (sigma_over_r6 - 2 * sigma_over_r6*sigma_over_r6);
		}
		
		float shifted_lj_force_r2(float dr2){
			return - (lj_prime_r2(dr2) - uprime_of_rc);
		}
}
