# RackStack Sample Use Case: Artifice

In this sample, we have a DogsAndCats class that aggreggates 
data from 2 websites, http://dogs.com and http://cats.com.

In our tests for this class, we use Artifice to override Net::HTTP with a mounted 
RackStack (with dogs.com and cats.com mounted to mock those sites' APIs).
