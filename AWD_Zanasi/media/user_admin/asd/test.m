x = 0:0.1:2*pi();
y = sin( x );
plot(x,y);
%print -dpng test.png;
saveas( gcf(), 'out\test.fig', 'fig' );
saveas( gcf(), 'out\test.png', 'png' );
exit()