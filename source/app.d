/// Run with: 'dub'
import particle_sim;

// Entry point to program
void main()
{
	ParticleSim app = ParticleSim("Lennard Jones Particle Simulation");
	app.RunLoop();
}
